const MAX_KEYWORD_LENGTH: usize = 26;
const MAX_MESSAGE_LENGTH: usize = 512;
const MAX_INPUT_LENGTH: usize = 3 + MAX_KEYWORD_LENGTH + MAX_MESSAGE_LENGTH + 1;

#[no_mangle]
pub unsafe extern "C" fn keyword_shifted_alphabet(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let raw = unsafe { std::slice::from_raw_parts(input, length) };
    let operation = raw[0];
    if (operation != 0 && operation != 1) || raw[1] < 1 || raw[1] > 26 ||
        raw[2] < 1 || raw[2] > MAX_MESSAGE_LENGTH as i64 { return -1; }
    let keyword_length = raw[1] as usize;
    let message_length = raw[2] as usize;
    if length != 3 + keyword_length + message_length { return -1; }

    let mut keyword = [0u8; MAX_KEYWORD_LENGTH];
    let mut seen = [false; 26];
    for i in 0..keyword_length {
        let value = raw[3 + i];
        if !((65..=90).contains(&value) || (97..=122).contains(&value)) { return -1; }
        let lower = if (65..=90).contains(&value) { (value + 32) as u8 } else { value as u8 };
        let index = (lower - b'a') as usize;
        if seen[index] { return -1; }
        seen[index] = true;
        keyword[i] = lower;
    }
    let mut message = [0u8; MAX_MESSAGE_LENGTH];
    for i in 0..message_length {
        let value = raw[3 + keyword_length + i];
        if !(0..=127).contains(&value) { return -1; }
        message[i] = value as u8;
    }

    let mut cipher_alphabet = [0u8; 26];
    let mut encode = [0u8; 26];
    let mut decode = [0u8; 26];
    let mut cipher_length = 0usize;
    for i in 0..keyword_length {
        cipher_alphabet[cipher_length] = keyword[i];
        cipher_length += 1;
    }
    for i in 0..26 {
        let letter = b'a' + i as u8;
        if !seen[i] {
            cipher_alphabet[cipher_length] = letter;
            cipher_length += 1;
        }
    }
    for i in 0..26 {
        encode[i] = cipher_alphabet[i];
        decode[(cipher_alphabet[i] - b'a') as usize] = b'a' + i as u8;
    }

    if output_capacity < message_length || output.is_null() { return -2; }
    for i in 0..message_length {
        let value = message[i];
        let uppercase = value.is_ascii_uppercase();
        let index = if uppercase { Some((value - b'A') as usize) }
            else if value.is_ascii_lowercase() { Some((value - b'a') as usize) }
            else { None };
        let Some(index) = index else { unsafe { *output.add(i) = value; } continue; };
        let translated = if operation == 0 { encode[index] } else { decode[index] };
        unsafe { *output.add(i) = if uppercase { translated - 32 } else { translated }; }
    }
    message_length as i64
}
