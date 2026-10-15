const INVALID_RESULT: i64 = -1;
const CAPACITY_RESULT: i64 = -2;

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn decimal_expansion(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 3 {
        return INVALID_RESULT;
    }
    let input = std::slice::from_raw_parts(values, length);
    let numerator = input[0];
    let denominator = input[1];
    let base = input[2];
    if numerator < 0 || !(1..=256).contains(&denominator) || numerator > denominator ||
        !(2..=10).contains(&base) {
        return INVALID_RESULT;
    }

    let mut digits = [0_u8; 255];
    let mut first_seen = [-1_i64; 256];
    let mut digit_count = 0_usize;
    let mut cycle_start = -1_i64;
    let mut remainder = numerator;
    while remainder != 0 && numerator != denominator {
        let remainder_index = remainder as usize;
        if first_seen[remainder_index] >= 0 {
            cycle_start = first_seen[remainder_index];
            break;
        }
        first_seen[remainder_index] = digit_count as i64;
        let scaled = remainder * base;
        digits[digit_count] = (scaled / denominator) as u8;
        digit_count += 1;
        remainder = scaled % denominator;
    }

    let required = 24 + digit_count;
    if output.is_null() || capacity < required {
        return CAPACITY_RESULT;
    }
    let target = std::slice::from_raw_parts_mut(output, required);
    write_i64_le(target, 0, if numerator == denominator { 1 } else { 0 });
    write_i64_le(target, 8, digit_count as i64);
    write_i64_le(target, 16, cycle_start);
    target[24..required].copy_from_slice(&digits[..digit_count]);
    required as i64
}
