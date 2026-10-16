/// Encrypt ASCII letters with a repeating decimal-digit Gronsfeld key.
#[no_mangle]
pub unsafe extern "C" fn gronsfeld(input: *const i64, length: usize,
                                    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 321 { return -1; }
    let mut separator = 0usize;
    while separator < length && *input.add(separator) != 0 { separator += 1; }
    if separator == length { return -1; }
    let text_length = separator;
    let key_length = length - separator - 1;
    if text_length > 256 || !(1..=64).contains(&key_length) { return -1; }

    for index in 0..text_length {
        let value = *input.add(index);
        if !(1..=127).contains(&value) { return -1; }
    }
    for index in 0..key_length {
        let value = *input.add(separator + 1 + index);
        if !(48..=57).contains(&value) { return -1; }
    }
    if output_capacity < text_length || (text_length > 0 && output.is_null()) { return -2; }

    let mut key_index = 0usize;
    for index in 0..text_length {
        let value = *input.add(index);
        let mut mapped = value;
        if (65..=90).contains(&value) {
            let shift = *input.add(separator + 1 + key_index % key_length) - 48;
            mapped = 65 + (value - 65 + shift) % 26;
            key_index += 1;
        } else if (97..=122).contains(&value) {
            let shift = *input.add(separator + 1 + key_index % key_length) - 48;
            mapped = 97 + (value - 97 + shift) % 26;
            key_index += 1;
        }
        *output.add(index) = mapped as u8;
    }
    text_length as i64
}
