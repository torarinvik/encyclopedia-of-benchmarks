/// Alphabetic Vernam cipher with a repeating key and modulo-26 arithmetic.
const MAX_VERNAM_LENGTH: usize = 1024;

#[no_mangle]
pub unsafe extern "C" fn vernam_cipher(input: *const i64, length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 3 + 2 * MAX_VERNAM_LENGTH { return -1; }
    let mode = *input;
    let text_length_value = *input.add(1);
    let key_length_value = *input.add(2);
    if (mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > MAX_VERNAM_LENGTH as i64
        || key_length_value < 1 || key_length_value > MAX_VERNAM_LENGTH as i64 { return -1; }
    let text_length = text_length_value as usize;
    let key_length = key_length_value as usize;
    if length != 3 + text_length + key_length { return -1; }
    let key_start = 3 + text_length;
    for i in 0..text_length {
        let value = *input.add(3 + i);
        if value < b'A' as i64 || value > b'Z' as i64 { return -1; }
    }
    for i in 0..key_length {
        let value = *input.add(key_start + i);
        if value < b'A' as i64 || value > b'Z' as i64 { return -1; }
    }
    if output_capacity < text_length || (text_length > 0 && output.is_null()) { return -2; }

    for i in 0..text_length {
        let text_value = *input.add(3 + i) - b'A' as i64;
        let key_value = *input.add(key_start + i % key_length) - b'A' as i64;
        let mapped = if mode == 0 { (text_value + key_value) % 26 }
                     else { (text_value - key_value + 26) % 26 };
        *output.add(i) = (b'A' as i64 + mapped) as u8;
    }
    text_length as i64
}
