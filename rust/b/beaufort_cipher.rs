/// Preserve the pinned Python source's plaintext-minus-repeating-key transform.
#[no_mangle]
pub unsafe extern "C" fn beaufort_cipher(input: *const i64, length: usize,
                                         output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 2051 { return -1; }
    let mode = *input;
    let text_length_value = *input.add(1);
    let key_length_value = *input.add(2);
    if (mode != 0 && mode != 1) || !(0..=1024).contains(&text_length_value)
        || !(0..=1024).contains(&key_length_value) { return -1; }
    let text_length = text_length_value as usize;
    let key_length = key_length_value as usize;
    if length != 3 + text_length + key_length || (text_length == 0 && key_length != 0)
        || (text_length != 0 && (key_length == 0 || key_length > text_length)) { return -1; }
    let key_start = 3 + text_length;
    for i in 0..text_length {
        let value = *input.add(3 + i);
        if value != b' ' as i64 && !(b'A' as i64..=b'Z' as i64).contains(&value) { return -1; }
    }
    for i in 0..key_length {
        let value = *input.add(key_start + i);
        if !(b'A' as i64..=b'Z' as i64).contains(&value) { return -1; }
    }
    if output_capacity < text_length || (text_length != 0 && output.is_null()) { return -2; }
    let mut key_index = 0usize;
    for i in 0..text_length {
        let value = *input.add(3 + i);
        if value == b' ' as i64 { *output.add(i) = b' '; continue; }
        let letter = value - b'A' as i64;
        let key = *input.add(key_start + key_index % key_length) - b'A' as i64;
        let mapped = if mode == 0 { (letter - key + 26) % 26 } else { (letter + key) % 26 };
        *output.add(i) = (b'A' as i64 + mapped) as u8;
        key_index += 1;
    }
    text_length as i64
}
