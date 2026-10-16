const MAX_STRING_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 3 + 2 * MAX_STRING_LENGTH;

fn fold_ascii(value: i64, mode: i64) -> i64 {
    if mode == 1 && (65..=90).contains(&value) { value + 32 } else { value }
}

#[no_mangle]
pub unsafe extern "C" fn comparison(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -2; }
    let packed = std::slice::from_raw_parts(values, length);
    let mode = packed[0];
    let first_length_value = packed[1];
    if (mode != 0 && mode != 1) || !(0..=MAX_STRING_LENGTH as i64).contains(&first_length_value) { return -2; }
    let first_length = first_length_value as usize;
    let second_length_position = 2 + first_length;
    if second_length_position >= length { return -2; }
    let second_length_value = packed[second_length_position];
    if !(0..=MAX_STRING_LENGTH as i64).contains(&second_length_value) { return -2; }
    let second_length = second_length_value as usize;
    let second_start = second_length_position + 1;
    if second_start + second_length != length { return -2; }
    let first = &packed[2..second_length_position];
    let second = &packed[second_start..];
    if first.iter().chain(second.iter()).any(|byte| !(1..=127).contains(byte)) { return -2; }

    for (&left, &right) in first.iter().zip(second.iter()) {
        let left = fold_ascii(left, mode);
        let right = fold_ascii(right, mode);
        if left < right { return -1; }
        if left > right { return 1; }
    }
    if first_length < second_length { return -1; }
    if first_length > second_length { return 1; }
    0
}
