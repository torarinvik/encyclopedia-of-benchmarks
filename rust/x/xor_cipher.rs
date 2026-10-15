/// XOR each input byte with a repeating key byte sequence.
#[no_mangle]
pub unsafe extern "C" fn xor_cipher(input: *const i64, length: usize,
                                     output: *mut u8, output_capacity: usize) -> i64 {
    if length < 3 || length > 66 { return -1; }
    let raw_text_length = *input;
    let raw_key_length = *input.add(1);
    if !(0..=63).contains(&raw_text_length) || !(1..=63).contains(&raw_key_length) { return -1; }
    let text_length = raw_text_length as usize;
    let key_length = raw_key_length as usize;
    if length != 2 + text_length + key_length { return -1; }
    for index in 0..text_length + key_length {
        let value = *input.add(2 + index);
        if !(0..=255).contains(&value) { return -1; }
    }
    if output_capacity < text_length { return -2; }
    for index in 0..text_length {
        let value = *input.add(2 + index) ^ *input.add(2 + text_length + index % key_length);
        *output.add(index) = value as u8;
    }
    text_length as i64
}
