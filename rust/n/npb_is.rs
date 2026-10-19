/// Independent port of the class-W NAS Parallel Benchmarks Integer Sort.
use std::sync::Mutex;

const TOTAL_KEYS: usize = 1 << 20;
const MAX_KEY: usize = 1 << 16;
const NUM_BUCKETS: usize = 1 << 10;
const MAX_ITERATIONS: usize = 10;
const TEST_INDICES: [usize; 5] = [357773, 934767, 875723, 898999, 404505];
const BASELINE_RANKS: [u32; 5] = [1249, 11698, 1039987, 1043896, 1048018];
const MAX_PASSES: i64 = 10;

struct Work {
    key_array: [u32; TOTAL_KEYS],
    key_buff2: [u32; TOTAL_KEYS],
    key_buff1: [u32; MAX_KEY],
    bucket_size: [u32; NUM_BUCKETS],
    bucket_ptrs: [u32; NUM_BUCKETS],
}

impl Work {
    const fn new() -> Self {
        Self {
            key_array: [0; TOTAL_KEYS],
            key_buff2: [0; TOTAL_KEYS],
            key_buff1: [0; MAX_KEY],
            bucket_size: [0; NUM_BUCKETS],
            bucket_ptrs: [0; NUM_BUCKETS],
        }
    }
}

static WORK: Mutex<Work> = Mutex::new(Work::new());

fn next_state(state: u64) -> u64 {
    const TWO23: u64 = 1 << 23;
    const LOW_MASK: u64 = TWO23 - 1;
    const STATE_MASK: u64 = (1 << 46) - 1;
    const MULTIPLIER_HIGH: u64 = 1220703125 / TWO23;
    const MULTIPLIER_LOW: u64 = 1220703125 % TWO23;
    let x1 = state >> 23;
    let x2 = state & LOW_MASK;
    let t1 = MULTIPLIER_HIGH * x2 + MULTIPLIER_LOW * x1;
    let z = t1 & LOW_MASK;
    ((z << 23) + MULTIPLIER_LOW * x2) & STATE_MASK
}

fn expected_rank(index: usize, iteration: u32) -> u32 {
    if index < 2 {
        (i64::from(BASELINE_RANKS[index]) + i64::from(iteration) - 2) as u32
    } else {
        BASELINE_RANKS[index] - iteration
    }
}

fn decimal_width(mut value: u32) -> usize {
    let mut width = 1;
    while value >= 10 { value /= 10; width += 1; }
    width
}

fn generate_keys(work: &mut Work) {
    let mut state = 314159265_u64;
    for index in 0..TOTAL_KEYS {
        let mut four_state_sum = 0_u64;
        for _ in 0..4 {
            state = next_state(state);
            four_state_sum += state;
        }
        work.key_array[index] = (four_state_sum >> 32) as u32;
    }
}

fn rank_pass(work: &mut Work, iteration: u32, partials: &mut [u32; 5]) {
    work.key_array[iteration as usize] = iteration;
    work.key_array[iteration as usize + MAX_ITERATIONS] = MAX_KEY as u32 - iteration;
    work.bucket_size.fill(0);
    for index in 0..TOTAL_KEYS {
        work.bucket_size[(work.key_array[index] >> 6) as usize] += 1;
    }
    work.bucket_ptrs[0] = 0;
    for bucket in 1..NUM_BUCKETS {
        work.bucket_ptrs[bucket] = work.bucket_ptrs[bucket - 1] + work.bucket_size[bucket - 1];
    }
    for index in 0..TOTAL_KEYS {
        let key = work.key_array[index];
        let bucket = (key >> 6) as usize;
        let position = work.bucket_ptrs[bucket] as usize;
        work.key_buff2[position] = key;
        work.bucket_ptrs[bucket] += 1;
    }
    work.key_buff1.fill(0);
    for index in 0..TOTAL_KEYS { work.key_buff1[work.key_buff2[index] as usize] += 1; }
    for key in 1..MAX_KEY { work.key_buff1[key] += work.key_buff1[key - 1]; }
    for test in 0..5 {
        let key = work.key_array[TEST_INDICES[test]] as usize;
        partials[test] = if key == 0 { 0 } else { work.key_buff1[key - 1] };
    }
}

fn full_verify(work: &mut Work) -> bool {
    for index in 0..TOTAL_KEYS {
        let key = work.key_buff2[index] as usize;
        work.key_buff1[key] -= 1;
        work.key_array[work.key_buff1[key] as usize] = key as u32;
    }
    for index in 1..TOTAL_KEYS {
        if work.key_array[index - 1] > work.key_array[index] { return false; }
    }
    true
}

unsafe fn append_decimal(value: u32, output: *mut u8, position: &mut usize) {
    let mut reversed = [0_u8; 10];
    let mut count = 0;
    let mut remaining = value;
    loop {
        reversed[count] = b'0' + (remaining % 10) as u8;
        count += 1;
        remaining /= 10;
        if remaining == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        unsafe { output.add(*position).write(reversed[count]); }
        *position += 1;
    }
}

#[no_mangle]
pub extern "C" fn npb_is(pass_count: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=MAX_PASSES).contains(&pass_count) { return -1; }
    let passes = pass_count as u32;
    if output.is_null() { return -2; }

    let mut staged = [0_u8; 353];
    let mut work = WORK.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
    generate_keys(&mut work);
    let mut partials = [0_u32; 5];
    rank_pass(&mut work, 1, &mut partials); // Untimed source warm-up.
    let mut passed_verification = 0_u32;
    let mut position = 0_usize;
    for iteration in 1..=passes {
        rank_pass(&mut work, iteration, &mut partials);
        let row_required = partials.iter().map(|value| decimal_width(*value)).sum::<usize>() + 5;
        if position + row_required > staged.len() { return -2; }
        for test in 0..5 {
            if partials[test] == expected_rank(test, iteration) { passed_verification += 1; }
            unsafe { append_decimal(partials[test], staged.as_mut_ptr(), &mut position); }
            if test + 1 < 5 {
                staged[position] = b',';
                position += 1;
            }
        }
        staged[position] = b'\n';
        position += 1;
    }
    if full_verify(&mut work) { passed_verification += 1; }
    if passed_verification != 5 * passes + 1 { passed_verification = 0; }
    if position + decimal_width(passed_verification) + 1 > staged.len() { return -2; }
    unsafe { append_decimal(passed_verification, staged.as_mut_ptr(), &mut position); }
    staged[position] = b'\n';
    position += 1;
    if output_capacity < position { return -2; }
    for index in 0..position { unsafe { output.add(index).write(staged[index]); } }
    position as i64
}
