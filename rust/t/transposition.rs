const MAX_KEY: usize = 32;
const MAX_TEXT: usize = 512;
const MAX_INPUT: usize = 3 + MAX_KEY + MAX_TEXT;
const MAX_PADDED: usize = MAX_TEXT + MAX_KEY;

fn ascii_letter(value: i64) -> bool {
    (b'A' as i64..=b'Z' as i64).contains(&value) || (b'a' as i64..=b'z' as i64).contains(&value)
}

fn hash_output(text: &[u8]) -> i64 {
    let mut hash = 14_695_981_039_346_656_037u64;
    let mut feed = |byte: u8| {
        hash = (hash ^ byte as u64).wrapping_mul(1_099_511_628_211);
    };
    for byte in (text.len() as u64).to_le_bytes() { feed(byte); }
    for &value in text {
        for byte in (value as u32).to_le_bytes() { feed(byte); }
    }
    (hash & 0x7fff_ffff_ffff_ffff) as i64
}

#[no_mangle]
pub unsafe extern "C" fn transposition(input_pointer: *const i64, length: usize) -> i64 {
    if input_pointer.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input_pointer, length) };
    let mode = input[0];
    let key_length_value = input[1];
    if (mode != 0 && mode != 1) || !(1..=MAX_KEY as i64).contains(&key_length_value) { return -1; }
    let key_length = key_length_value as usize;
    let text_length_index = 2 + key_length;
    if length <= text_length_index { return -1; }
    let text_length_value = input[text_length_index];
    if !(1..=MAX_TEXT as i64).contains(&text_length_value) { return -1; }
    let text_length = text_length_value as usize;
    if length != text_length_index + 1 + text_length { return -1; }

    let mut key = [0u8; MAX_KEY];
    let mut sorted = [0u8; MAX_KEY];
    for index in 0..key_length {
        let value = input[2 + index];
        if !ascii_letter(value) { return -1; }
        let mut ch = value as u8;
        if ch.is_ascii_uppercase() { ch = ch.to_ascii_lowercase(); }
        key[index] = ch;
        sorted[index] = ch;
    }
    sorted[..key_length].sort_unstable();
    let mut ranks = [0usize; MAX_KEY];
    for index in 0..key_length {
        let first = sorted[..key_length].iter().position(|&value| value == key[index]).unwrap_or(0);
        let duplicate = key[..index].iter().filter(|&&value| value == key[index]).count();
        ranks[index] = first + duplicate + 1;
    }
    let mut text = [0u8; MAX_PADDED];
    for index in 0..text_length {
        let value = input[text_length_index + 1 + index];
        if !(32..=126).contains(&value) { return -1; }
        text[index] = value as u8;
    }
    if mode == 0 && text[text_length - 1] == b' ' { return -1; }
    let padding = key_length - text_length % key_length;
    let padded_length = text_length + padding;
    for byte in &mut text[text_length..padded_length] { *byte = b' '; }
    let mut result = [0u8; MAX_PADDED];
    let mut result_length = 0;
    if mode == 0 {
        for start in (0..padded_length).step_by(key_length) {
            let mut block = [0u8; MAX_KEY];
            for offset in 0..key_length { block[ranks[offset] - 1] = text[start + offset]; }
            for &byte in &block[..key_length] { result[result_length] = byte; result_length += 1; }
        }
    } else {
        for start in (0..text_length).step_by(key_length) {
            for offset in 0..key_length { result[result_length] = text[start + ranks[offset] - 1]; result_length += 1; }
        }
        while result_length > 0 && result[result_length - 1] == b' ' { result_length -= 1; }
    }
    hash_output(&result[..result_length])
}
