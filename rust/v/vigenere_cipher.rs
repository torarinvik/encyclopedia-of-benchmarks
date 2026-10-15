/// Encrypt ASCII text with a repeating, case-insensitive Vigenere key.
#[no_mangle]
pub unsafe extern "C" fn vigenere_cipher(input: *const i64, length: usize,
                                           output: *mut u8, output_capacity: usize) -> i64 {
    if !(2..=66).contains(&length) { return -1; }
    let mut separator = 0usize;
    while separator < length && *input.add(separator) != 0 { separator += 1; }
    if separator == length || separator + 1 == length { return -1; }
    let key_length = length - separator - 1;
    for index in 0..separator {
        let value = *input.add(index);
        if !(1..=127).contains(&value) { return -1; }
    }
    for index in 0..key_length {
        let value = *input.add(separator + 1 + index);
        if !((65..=90).contains(&value) || (97..=122).contains(&value)) { return -1; }
    }
    if output_capacity < separator { return -2; }

    let mut key_index = 0usize;
    for index in 0..separator {
        let value = *input.add(index);
        let mut mapped = value;
        if (65..=90).contains(&value) {
            let mut key_value = *input.add(separator + 1 + key_index);
            if key_value >= 97 { key_value -= 32; }
            mapped = 65 + (value - 65 + key_value - 65) % 26;
            key_index = (key_index + 1) % key_length;
        } else if (97..=122).contains(&value) {
            let mut key_value = *input.add(separator + 1 + key_index);
            if key_value <= 90 { key_value += 32; }
            mapped = 97 + (value - 97 + key_value - 97) % 26;
            key_index = (key_index + 1) % key_length;
        }
        *output.add(index) = mapped as u8;
    }
    separator as i64
}
