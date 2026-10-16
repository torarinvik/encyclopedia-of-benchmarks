const MAX_ALPHABET_LENGTH: usize = 32;
const MAX_TEXT_LENGTH: usize = 128;

#[no_mangle]
pub unsafe extern "C" fn move_to_front(values: *const i64, length: usize,
                                          output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || !(3..=164).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let mode = input[0];
    let alphabet_length = input[1];
    let text_length = input[2];
    if (mode != 0 && mode != 1) || !(0..=MAX_ALPHABET_LENGTH as i64).contains(&alphabet_length)
        || !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length)
        || length != 3 + alphabet_length as usize + text_length as usize { return -1; }
    let mut alphabet = [0i64; MAX_ALPHABET_LENGTH];
    let mut result = [0u8; MAX_TEXT_LENGTH];
    for i in 0..alphabet_length as usize {
        let symbol = input[3 + i];
        if !(0..=127).contains(&symbol) || alphabet[..i].contains(&symbol) { return -1; }
        alphabet[i] = symbol;
    }
    let mut result_length = 0usize;
    if mode == 0 {
        if text_length > 0 && alphabet_length == 0 { return -1; }
        for &symbol in &input[3 + alphabet_length as usize..] {
            if !(0..=127).contains(&symbol) { return -1; }
            let Some(position) = alphabet[..alphabet_length as usize].iter().position(|&value| value == symbol) else {
                return -1;
            };
            result[result_length] = position as u8;
            result_length += 1;
            for j in (1..=position).rev() { alphabet[j] = alphabet[j - 1]; }
            alphabet[0] = symbol;
        }
    } else if alphabet_length > 0 {
        for &index in &input[3 + alphabet_length as usize..] {
            if index < 0 || index >= alphabet_length { return -1; }
            let position = index as usize;
            let symbol = alphabet[position];
            result[result_length] = symbol as u8;
            result_length += 1;
            for j in (1..=position).rev() { alphabet[j] = alphabet[j - 1]; }
            alphabet[0] = symbol;
        }
    }
    if capacity < result_length || (result_length > 0 && output.is_null()) { return -2; }
    if result_length > 0 { std::ptr::copy_nonoverlapping(result.as_ptr(), output, result_length); }
    result_length as i64
}
