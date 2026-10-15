/// Plaintext-autokey cipher with a selectable output case dialect.
const MAX_AUTOKEY_LENGTH: usize = 1024;

unsafe fn uppercase_letter(value: i64) -> i64 {
    if (b'a' as i64..=b'z' as i64).contains(&value) { value - 32 } else { value }
}

#[no_mangle]
pub unsafe extern "C" fn autokey_cipher(input: *const i64, length: usize,
                                          output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > 4 + 2 * MAX_AUTOKEY_LENGTH { return -1; }
    let mode = *input;
    let dialect = *input.add(1);
    let text_length_value = *input.add(2);
    let key_length_value = *input.add(3);
    if (mode != 0 && mode != 1) || (dialect != 0 && dialect != 1)
        || text_length_value < 1 || text_length_value > MAX_AUTOKEY_LENGTH as i64
        || key_length_value < 1 || key_length_value > MAX_AUTOKEY_LENGTH as i64 { return -1; }
    let text_length = text_length_value as usize;
    let key_length = key_length_value as usize;
    if length != 4 + text_length + key_length { return -1; }
    let key_start = 4 + text_length;
    for i in 0..text_length {
        let value = *input.add(4 + i);
        if !((b'A' as i64..=b'Z' as i64).contains(&value) || (b'a' as i64..=b'z' as i64).contains(&value)) { return -1; }
        if dialect == 1 && mode == 1 && (b'A' as i64..=b'Z' as i64).contains(&value) { return -1; }
    }
    for i in 0..key_length {
        let value = *input.add(key_start + i);
        if !((b'A' as i64..=b'Z' as i64).contains(&value) || (b'a' as i64..=b'z' as i64).contains(&value)) { return -1; }
    }
    if output_capacity < text_length || output.is_null() { return -2; }
    for i in 0..text_length {
        let plain = uppercase_letter(*input.add(4 + i)) - b'A' as i64;
        let key_value = if i < key_length { uppercase_letter(*input.add(key_start + i)) }
            else if mode == 0 { uppercase_letter(*input.add(4 + i - key_length)) }
            else { uppercase_letter(*output.add(i - key_length) as i64) };
        let shift = key_value - b'A' as i64;
        let mapped = if mode == 0 { (plain + shift) % 26 } else { (plain - shift + 26) % 26 };
        let result = b'A' as i64 + mapped + if dialect == 1 { 32 } else { 0 };
        *output.add(i) = result as u8;
    }
    text_length as i64
}
