/// Keyed Morse trigraph fractionation.
const MORSE_CODE: [u8; 26] = [1,8,10,4,0,2,6,0,0,7,5,4,3,2,7,6,13,2,0,1,1,1,3,9,11,12];
const MORSE_LENGTH: [usize; 26] = [2,4,4,3,1,4,3,4,2,4,3,4,2,2,3,4,4,3,3,1,3,4,3,4,4,4];
const MORSE_SYMBOLS: [u8; 3] = [b'.', b'-', b'x'];

fn make_keyed_alphabet(input: &[i64], start: usize, length: usize) -> [u8; 26] {
    let mut keyed = [0u8; 26]; let mut seen = [false; 26]; let mut count = 0usize;
    for index in 0..length {
        let value = if (b'a' as i64..=b'z' as i64).contains(&input[start + index]) { input[start + index] - 32 } else { input[start + index] };
        let letter = (value - b'A' as i64) as usize;
        if !seen[letter] { seen[letter] = true; keyed[count] = value as u8; count += 1; }
    }
    for letter in 0..26 { if !seen[letter] { keyed[count] = b'A' + letter as u8; count += 1; } }
    keyed
}

fn morse_letter(morse: &[u8]) -> Option<u8> {
    if morse.is_empty() || morse.len() > 4 { return None; }
    let mut code = 0u8;
    for &symbol in morse { code = code * 2 + u8::from(symbol == b'-'); }
    (0..26).find(|&letter| MORSE_LENGTH[letter] == morse.len() && MORSE_CODE[letter] == code).map(|letter| b'A' + letter as u8)
}

#[no_mangle]
pub unsafe extern "C" fn fractionated_morse_cipher(input: *const i64, length: usize,
                                                    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 323 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    let mode = input[0]; let text_value = input[1]; let key_value = input[2];
    if (mode != 0 && mode != 1) || !(0..=256).contains(&text_value) || !(0..=64).contains(&key_value) { return -1; }
    let text_length = text_value as usize; let key_length = key_value as usize;
    if length != 3 + text_length + key_length { return -1; }
    let key_start = 3 + text_length;
    for &value in &input[key_start..] {
        if !((b'A' as i64..=b'Z' as i64).contains(&value) || (b'a' as i64..=b'z' as i64).contains(&value)) { return -1; }
    }
    for &value in &input[3..key_start] {
        if mode == 0 {
            if value != b' ' as i64 && !((b'A' as i64..=b'Z' as i64).contains(&value) || (b'a' as i64..=b'z' as i64).contains(&value)) { return -1; }
        } else if !(b'A' as i64..=b'Z' as i64).contains(&value) { return -1; }
    }
    let keyed = make_keyed_alphabet(input, key_start, key_length);
    let mut result = [0u8; 800]; let mut result_length = 0usize;
    if mode == 0 {
        let mut morse = [0u8; 1300]; let mut morse_length = 0usize;
        for index in 0..text_length {
            if index != 0 { morse[morse_length] = b'x'; morse_length += 1; }
            let mut value = input[3 + index];
            if value == b' ' as i64 { continue; }
            if (b'a' as i64..=b'z' as i64).contains(&value) { value -= 32; }
            let letter = (value - b'A' as i64) as usize;
            for bit in 0..MORSE_LENGTH[letter] {
                morse[morse_length] = if MORSE_CODE[letter] & (1 << (MORSE_LENGTH[letter] - bit - 1)) != 0 { b'-' } else { b'.' };
                morse_length += 1;
            }
        }
        let padding = 3 - morse_length % 3;
        for _ in 0..padding { morse[morse_length] = b'x'; morse_length += 1; }
        for start in (0..morse_length).step_by(3) {
            let mut trigram = 0usize;
            for symbol in &morse[start..start + 3] { trigram = trigram * 3 + if *symbol == b'.' { 0 } else if *symbol == b'-' { 1 } else { 2 }; }
            if trigram < 26 { result[result_length] = keyed[trigram]; result_length += 1; }
        }
    } else {
        let mut morse = [0u8; 1300]; let mut morse_length = 0usize;
        for &value in &input[3..key_start] {
            let trigram = keyed.iter().position(|&letter| letter as i64 == value).unwrap_or(26);
            if trigram == 26 { return -1; }
            morse[morse_length] = MORSE_SYMBOLS[trigram / 9];
            morse[morse_length + 1] = MORSE_SYMBOLS[(trigram / 3) % 3];
            morse[morse_length + 2] = MORSE_SYMBOLS[trigram % 3];
            morse_length += 3;
        }
        let mut segment_start = 0usize;
        for index in 0..=morse_length {
            if index != morse_length && morse[index] != b'x' { continue; }
            let segment = &morse[segment_start..index];
            if segment.is_empty() { result[result_length] = b' '; result_length += 1; }
            else if let Some(letter) = morse_letter(segment) { result[result_length] = letter; result_length += 1; }
            else { return -1; }
            segment_start = index + 1;
        }
        let first = result[..result_length].iter().position(|&byte| byte != b' ').unwrap_or(result_length);
        while result_length > first && result[result_length - 1] == b' ' { result_length -= 1; }
        if first != 0 { result.copy_within(first..result_length, 0); result_length -= first; }
    }
    if output_capacity < result_length || (result_length != 0 && output.is_null()) { return -2; }
    for index in 0..result_length { *output.add(index) = result[index]; }
    result_length as i64
}
