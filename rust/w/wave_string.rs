fn is_ascii_letter(value: i64) -> bool {
    (65..=90).contains(&value) || (97..=122).contains(&value)
}

#[no_mangle]
pub unsafe extern "C" fn wave_string(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    const MAX_TEXT_LENGTH: usize = 512;
    if values.is_null() || length < 1 {
        return -1;
    }
    let text_length_value = *values;
    if !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length_value)
        || length != 1 + text_length_value as usize
    {
        return -1;
    }
    let text_length = text_length_value as usize;
    let mut letter_count = 0;
    for index in 0..text_length {
        let byte = *values.add(index + 1);
        if !(32..=126).contains(&byte) {
            return -1;
        }
        if is_ascii_letter(byte) {
            letter_count += 1;
        }
    }
    let output_length = letter_count * (text_length + 2);
    if output_length > output_capacity || (output_length > 0 && output.is_null()) {
        return -2;
    }

    let mut written = 0;
    for position in 0..text_length {
        if !is_ascii_letter(*values.add(position + 1)) {
            continue;
        }
        *output.add(written) = (text_length & 255) as u8;
        *output.add(written + 1) = (text_length >> 8) as u8;
        written += 2;
        for index in 0..text_length {
            let mut byte = *values.add(index + 1);
            if index == position && (97..=122).contains(&byte) {
                byte -= 32;
            }
            *output.add(written) = byte as u8;
            written += 1;
        }
    }
    letter_count as i64
}
