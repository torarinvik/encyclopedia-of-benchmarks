/// Apply a normalized Caesar shift to ASCII letters in a byte sequence.
#[no_mangle]
pub unsafe extern "C" fn caesar_cipher(input: *const i64, length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if length == 0 || length > 66 { return -1; }
    let text_length = length - 1;
    for index in 0..text_length {
        let value = *input.add(index);
        if !(0..=127).contains(&value) { return -1; }
    }
    if output_capacity < text_length { return -2; }

    let mut shift = *input.add(text_length) % 26;
    if shift < 0 { shift += 26; }
    for index in 0..text_length {
        let value = *input.add(index);
        let mapped = if (65..=90).contains(&value) {
            65 + (value - 65 + shift) % 26
        } else if (97..=122).contains(&value) {
            97 + (value - 97 + shift) % 26
        } else {
            value
        };
        *output.add(index) = mapped as u8;
    }
    text_length as i64
}
