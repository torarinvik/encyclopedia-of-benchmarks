/// Reciprocal Porta tableau cipher.
#[no_mangle]
pub unsafe extern "C" fn porta_cipher(input: *const i64, length: usize,
                                      output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 1091 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let mode = input[0]; let text_value = input[1]; let key_value = input[2];
    if (mode != 0 && mode != 1) || !(0..=1024).contains(&text_value) || !(0..=64).contains(&key_value) { return -1; }
    let text_length = text_value as usize; let key_length = key_value as usize;
    if length != 3 + text_length + key_length || (text_length != 0 && key_length == 0) { return -1; }
    let key_start = 3 + text_length;
    for &value in &input[3..] {
        if !((b'A' as i64..=b'Z' as i64).contains(&value) || (b'a' as i64..=b'z' as i64).contains(&value)) { return -1; }
    }
    if output_capacity < text_length || (text_length != 0 && output.is_null()) { return -2; }
    for index in 0..text_length {
        let mut letter = input[3 + index];
        let mut key_letter = input[key_start + index % key_length];
        if letter >= b'a' as i64 { letter -= 32; }
        if key_letter >= b'a' as i64 { key_letter -= 32; }
        let letter_index = letter - b'A' as i64;
        let group = (key_letter - b'A' as i64) / 2;
        let mapped = if letter_index < 13 { 13 + (letter_index + 13 - group) % 13 }
                     else { (letter_index - 13 + group) % 13 };
        *output.add(index) = (b'A' as i64 + mapped) as u8;
    }
    text_length as i64
}
