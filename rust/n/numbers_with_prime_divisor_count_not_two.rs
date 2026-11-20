const MAX_INPUT_LENGTH: usize = 2;
const MAX_LIMIT: usize = 1000;

fn is_prime_count(value: u16) -> bool {
    if value < 2 { return false; }
    let mut divisor = 2_u16;
    while divisor <= value / divisor {
        if value % divisor == 0 { return false; }
        divisor += 1;
    }
    true
}

fn store_i64(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn numbers_with_prime_divisor_count_not_two(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if length != 1 || values[0] < 1 || values[0] > MAX_LIMIT as i64 { return -1; }
    if output.is_null() { return -2; }

    let limit = values[0] as usize;
    let mut divisor_counts = [0_u16; MAX_LIMIT];
    for divisor in 1..limit {
        let mut multiple = divisor;
        while multiple < limit {
            divisor_counts[multiple] += 1;
            multiple += divisor;
        }
    }
    let selected_count = (1..limit)
        .filter(|&n| divisor_counts[n] != 2 && is_prime_count(divisor_counts[n]))
        .count();
    let output_bytes = selected_count * 8;
    if capacity < output_bytes { return -2; }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    let mut output_index = 0;
    for n in 1..limit {
        let count = divisor_counts[n];
        if count != 2 && is_prime_count(count) {
            store_i64(output_slice, output_index * 8, n as i64);
            output_index += 1;
        }
    }
    output_bytes as i64
}
