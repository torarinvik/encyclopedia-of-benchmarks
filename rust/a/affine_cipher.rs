const MAX_INPUT_VALUES: usize = 612;
const MAX_TEXT_LENGTH: usize = 512;

fn inverse_mod(value: i64, modulus: i64) -> i64 {
    for candidate in 1..modulus {
        if (value * candidate) % modulus == 1 { return candidate; }
    }
    -1
}

#[no_mangle]
pub unsafe extern "C" fn affine_cipher(values: *const i64, length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if values.is_null() || length < 7 || length > MAX_INPUT_VALUES { return -1; }
    let mode = *values;
    let key_a = *values.add(1);
    let key_b = *values.add(2);
    let alphabet_arg = *values.add(3);
    if !(0..=1).contains(&mode) || !(2..=95).contains(&alphabet_arg) { return -1; }
    let alphabet_length = alphabet_arg as usize;
    let text_length_index = 4 + alphabet_length;
    if length <= text_length_index { return -1; }
    let text_length_arg = *values.add(text_length_index);
    if key_a < 0 || key_a > 1_000_000 || key_b < 0 || key_b >= alphabet_arg ||
        text_length_arg < 0 || text_length_arg > MAX_TEXT_LENGTH as i64 ||
        length != text_length_index + 1 + text_length_arg as usize ||
        gcd_i64(key_a, alphabet_arg) != 1 { return -1; }
    let text_length = text_length_arg as usize;

    let mut positions = [-1i16; 128];
    for index in 0..alphabet_length {
        let symbol = *values.add(4 + index);
        if !(32..=126).contains(&symbol) || positions[symbol as usize] != -1 { return -1; }
        positions[symbol as usize] = index as i16;
    }
    for index in 0..text_length {
        let symbol = *values.add(text_length_index + 1 + index);
        if !(32..=126).contains(&symbol) || positions[symbol as usize] < 0 { return -1; }
    }
    if text_length > output_capacity || (text_length != 0 && output.is_null()) { return -2; }

    let multiplier = key_a % alphabet_arg;
    let inverse = if mode == 1 { inverse_mod(multiplier, alphabet_arg) } else { 0 };
    for index in 0..text_length {
        let symbol = *values.add(text_length_index + 1 + index);
        let position = positions[symbol as usize] as i64;
        let mapped = if mode == 0 {
            (position * multiplier + key_b) % alphabet_arg
        } else {
            ((position - key_b + alphabet_arg) % alphabet_arg * inverse) % alphabet_arg
        };
        *output.add(index) = *values.add(4 + mapped as usize) as u8;
    }
    text_length as i64
}

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}
