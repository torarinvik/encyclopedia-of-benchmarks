const MAX_ITERATIONS: i64 = 1_125_000;
const NIBBLE_BITS: [i32; 16] = [0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4];
const INITIAL_SEEDS: [u32; 7] = [16839, 18985, 21520, 3905, 10113, 8672, 21285];

fn count_kernighan(mut value: u32) -> i32 {
    let mut count = 0;
    while value != 0 {
        value &= value - 1;
        count += 1;
    }
    count
}

fn count_parallel(mut value: u32) -> i32 {
    value = ((value & 0xAAAAAAAA) >> 1) + (value & 0x55555555);
    value = ((value & 0xCCCCCCCC) >> 2) + (value & 0x33333333);
    value = ((value & 0xF0F0F0F0) >> 4) + (value & 0x0F0F0F0F);
    value = ((value & 0xFF00FF00) >> 8) + (value & 0x00FF00FF);
    value = ((value & 0xFFFF0000) >> 16) + (value & 0x0000FFFF);
    value as i32
}

fn count_recursive_nybbles(value: u32) -> i32 {
    let count = NIBBLE_BITS[(value & 0xF) as usize];
    if value >> 4 == 0 { count } else { count + count_recursive_nybbles(value >> 4) }
}

fn count_fixed_nybbles(value: u32) -> i32 {
    let mut count = 0;
    for shift in (0..32).step_by(4) { count += NIBBLE_BITS[((value >> shift) & 0xF) as usize]; }
    count
}

fn count_byte(value: u32) -> i32 {
    NIBBLE_BITS[(value & 0xF) as usize] + NIBBLE_BITS[((value >> 4) & 0xF) as usize]
}

fn count_bw_bytes(value: u32) -> i32 {
    count_byte(value) + count_byte(value >> 8) + count_byte(value >> 24) + count_byte(value >> 16)
}

fn count_ar_bytes(value: u32) -> i32 {
    let mut count = 0;
    for index in 0..4 { count += count_byte(value >> (index * 8)); }
    count
}

fn count_shift_test(mut value: u32) -> i32 {
    let mut count = 0;
    for _ in 0..64 {
        if value == 0 { break; }
        count += (value & 1) as i32;
        value >>= 1;
    }
    count
}

fn count_selected(algorithm: usize, value: u32) -> i32 {
    match algorithm {
        0 => count_kernighan(value),
        1 => count_parallel(value),
        2 => count_recursive_nybbles(value),
        3 => count_fixed_nybbles(value),
        4 => count_bw_bytes(value),
        5 => count_ar_bytes(value),
        _ => count_shift_test(value),
    }
}

#[no_mangle]
pub extern "C" fn automotive_bitcount(iterations: i64) -> i64 {
    if !(0..=MAX_ITERATIONS).contains(&iterations) { return -1; }
    let mut result = 0_i64;
    for algorithm in 0..7 {
        let mut seed = INITIAL_SEEDS[algorithm];
        let mut total = 0_i64;
        for _ in 0..iterations {
            total += i64::from(count_selected(algorithm, seed));
            seed += 13;
        }
        result += (algorithm as i64 + 1) * total;
    }
    result
}
