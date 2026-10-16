/// Count A/C/G/T and return all four counts as an ASCII string.
const MAX_SEQUENCE_LENGTH: i64 = 1_000;

fn decimal_length(mut value: i64) -> usize {
    let mut length = 1;
    while value >= 10 { value /= 10; length += 1; }
    length
}

fn write_decimal(output: &mut [u8], mut offset: usize, mut value: i64) -> usize {
    let mut divisor = 1_i64;
    while value / divisor >= 10 { divisor *= 10; }
    while divisor > 0 {
        output[offset] = b'0' + (value / divisor) as u8;
        offset += 1;
        value %= divisor;
        divisor /= 10;
    }
    offset
}

#[no_mangle]
pub unsafe extern "C" fn count_nucleotide(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 1 || length > 1_001 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let count_value = input[0];
    if !(0..=MAX_SEQUENCE_LENGTH).contains(&count_value) || length != count_value as usize + 1 { return -1; }
    let mut count_a = 0_i64;
    let mut count_c = 0_i64;
    let mut count_g = 0_i64;
    let mut count_t = 0_i64;
    for codepoint in &input[1..] {
        if !(0..=127).contains(codepoint) { return -1; }
        if *codepoint == 65 { count_a += 1; }
        else if *codepoint == 67 { count_c += 1; }
        else if *codepoint == 71 { count_g += 1; }
        else if *codepoint == 84 { count_t += 1; }
    }
    let output_length = decimal_length(count_a) + decimal_length(count_c) +
        decimal_length(count_g) + decimal_length(count_t) + 3;
    if output.is_null() || capacity < output_length { return -2; }
    let result = std::slice::from_raw_parts_mut(output, output_length);
    let mut offset = write_decimal(result, 0, count_a); result[offset] = b' '; offset += 1;
    offset = write_decimal(result, offset, count_c); result[offset] = b' '; offset += 1;
    offset = write_decimal(result, offset, count_g); result[offset] = b' '; offset += 1;
    offset = write_decimal(result, offset, count_t);
    offset as i64
}
