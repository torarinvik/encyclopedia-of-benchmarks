#[no_mangle]
pub unsafe extern "C" fn hill_cipher_mod26_java(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(1..=257).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] != 0 && values[0] != 1 { return -1; }
    let key = if values[0] == 0 { [3_i64, 3, 2, 5] } else { [15_i64, 17, 20, 9] };
    let mut text = [0_u8; 256]; let mut text_length = 0_usize;
    for &raw in &values[1..] {
        if !(0..=127).contains(&raw) { return -1; }
        let mut c = raw as u8;
        if c.is_ascii_lowercase() { c = c.to_ascii_uppercase(); }
        if c.is_ascii_uppercase() { text[text_length] = c; text_length += 1; }
    }
    if text_length & 1 == 1 { text[text_length] = b'X'; text_length += 1; }
    if text_length > capacity || (text_length > 0 && output.is_null()) { return -2; }
    if text_length > 0 {
        let result = std::slice::from_raw_parts_mut(output, text_length);
        for i in (0..text_length).step_by(2) {
            let a = (text[i] - b'A') as i64; let b = (text[i + 1] - b'A') as i64;
            result[i] = b'A' + ((key[0] * a + key[1] * b) % 26) as u8;
            result[i + 1] = b'A' + ((key[2] * a + key[3] * b) % 26) as u8;
        }
    }
    text_length as i64
}
