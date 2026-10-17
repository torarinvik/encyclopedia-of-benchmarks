const MAX_PASSCODE_LENGTH: usize = 20;
const MAX_TEXT_LENGTH: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 279;
const ALPHABET_LENGTH: usize = 97;

fn parse(input: &[i64]) -> Option<([u8; MAX_PASSCODE_LENGTH], usize, [u8; MAX_TEXT_LENGTH], usize)> {
    if input.len() < 2 || input.len() > MAX_PARSEABLE_INPUT_LENGTH { return None; }
    let pass_len_value = input[0];
    let text_len_value = input[1];
    if !(1..=MAX_PASSCODE_LENGTH as i64).contains(&pass_len_value)
        || !(0..=MAX_TEXT_LENGTH as i64).contains(&text_len_value) { return None; }
    let pass_len = pass_len_value as usize;
    let text_len = text_len_value as usize;
    if input.len() != 2 + pass_len + text_len { return None; }

    let mut passcode = [0_u8; MAX_PASSCODE_LENGTH];
    for i in 0..pass_len {
        let value = input[2 + i];
        if !(48..=57).contains(&value) && !(65..=90).contains(&value) && !(97..=122).contains(&value) { return None; }
        passcode[i] = value as u8;
    }
    let mut plaintext = [0_u8; MAX_TEXT_LENGTH];
    let text_start = 2 + pass_len;
    for i in 0..text_len {
        let value = input[text_start + i];
        let valid = (32..=126).contains(&value) || value == 9 || value == 10;
        if !valid { return None; }
        plaintext[i] = value as u8;
    }
    Some((passcode, pass_len, plaintext, text_len))
}

fn is_alphanumeric(byte: u8) -> bool {
    byte.is_ascii_alphanumeric()
}

#[no_mangle]
pub unsafe extern "C" fn shuffled_shift_cipher(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let Some((passcode, pass_len, plaintext, text_len)) = parse(values) else { return -1; };
    if output.is_null() || output_capacity < text_len { return -2; }

    let mut breakpoints = [false; 128];
    let mut shift_sum = 0_i64;
    for i in 0..pass_len {
        let byte = passcode[i];
        breakpoints[byte as usize] = true;
        if i % 2 == 0 { shift_sum += i64::from(byte); } else { shift_sum -= i64::from(byte); }
    }
    let shift = if shift_sum > 0 { shift_sum as usize } else { pass_len };

    let mut alphabet = [0_u8; ALPHABET_LENGTH];
    let mut alphabet_len = 0;
    for byte in b'a'..=b'z' { alphabet[alphabet_len] = byte; alphabet_len += 1; }
    for byte in b'A'..=b'Z' { alphabet[alphabet_len] = byte; alphabet_len += 1; }
    for byte in b'0'..=b'9' { alphabet[alphabet_len] = byte; alphabet_len += 1; }
    for byte in b'!'..=b'~' {
        if !is_alphanumeric(byte) { alphabet[alphabet_len] = byte; alphabet_len += 1; }
    }
    alphabet[alphabet_len] = b' '; alphabet_len += 1;
    alphabet[alphabet_len] = b'\t'; alphabet_len += 1;
    alphabet[alphabet_len] = b'\n'; alphabet_len += 1;

    let mut key = [0_u8; ALPHABET_LENGTH];
    let mut key_len = 0;
    let mut segment = [0_u8; ALPHABET_LENGTH];
    let mut segment_len = 0;
    for index in 0..alphabet_len {
        let byte = alphabet[index];
        segment[segment_len] = byte;
        segment_len += 1;
        if breakpoints[byte as usize] || index + 1 == alphabet_len {
            while segment_len > 0 {
                segment_len -= 1;
                key[key_len] = segment[segment_len];
                key_len += 1;
            }
        }
    }

    for i in 0..text_len {
        let mut key_index = 0;
        while key_index < key_len && key[key_index] != plaintext[i] { key_index += 1; }
        let shifted = (key_index + shift) % ALPHABET_LENGTH;
        *output.add(i) = key[shifted];
    }
    text_len as i64
}
