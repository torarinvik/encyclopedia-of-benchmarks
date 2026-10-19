const MAX_ARRAY_SIZE: i64 = 100_000;
const MAX_ROUNDS: i64 = 8;
const MAX_SCANS_PER_ARRAY: i64 = 64;

fn puzzle_rand(state: &mut u64) -> u32 {
    *state = state.wrapping_mul(1_103_515_245).wrapping_add(12_345);
    ((*state >> 16) as u32) % 32_767 + 1
}

fn puzzle_rand_int(minimum: usize, maximum: usize, state: &mut u64) -> usize {
    let range = maximum - minimum + 1;
    let draw = puzzle_rand(state);
    let offset = (range as f64 * (draw as f64 / 32_768.0)) as usize;
    if offset == range { offset + minimum - 1 } else { offset + minimum }
}

fn puzzle_shuffle(items: &mut [i32], state: &mut u64) {
    for index in (1..items.len()).rev() {
        let range = index + 1;
        let draw = puzzle_rand(state);
        let k = (range as f64 * (draw as f64 / 32_768.0)) as usize;
        let chosen = if k == range { k - 1 } else { k };
        items.swap(index, chosen);
    }
}

fn puzzle_find_duplicate(data: &[i32]) -> i32 {
    let mut result = 0u32;
    for (index, item) in data.iter().enumerate() {
        result ^= (index as u32 + 1) ^ (*item as u32);
    }
    result ^= data.len() as u32;
    result as i32
}

unsafe fn puzzle_store_i32_le(output: *mut u8, offset: usize, value: i32) {
    let bits = value as u32;
    for byte in 0..4 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn benchmarkgame_puzzle(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let raw_size = *input;
    let raw_rounds = *input.add(1);
    let raw_scans = *input.add(2);
    if !(1..=MAX_ARRAY_SIZE).contains(&raw_size)
        || !(1..=MAX_ROUNDS).contains(&raw_rounds)
        || !(1..=MAX_SCANS_PER_ARRAY).contains(&raw_scans)
    { return -1; }
    let size = raw_size as usize;
    let rounds = raw_rounds as usize;
    let scans = raw_scans as usize;
    let output_bytes = rounds * 4;
    if output_capacity < output_bytes || output.is_null() { return -2; }

    let mut random_state = 1u64;
    for round in 0..rounds {
        let mut data: Vec<i32> = (0..=size as i32).collect();
        data[0] = puzzle_rand_int(1, size, &mut random_state) as i32;
        puzzle_shuffle(&mut data, &mut random_state);
        let mut duplicate = 0;
        for _ in 0..scans { duplicate = puzzle_find_duplicate(&data); }
        puzzle_store_i32_le(output, round * 4, duplicate);
    }
    output_bytes as i64
}
