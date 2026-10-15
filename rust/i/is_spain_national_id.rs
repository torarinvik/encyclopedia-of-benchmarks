const CHECK_LETTERS: &[u8; 23] = b"TRWAGMYFPDXBNJZSQVHLCKE";

#[no_mangle]
pub unsafe extern "C" fn is_spain_national_id(input: *const i64, length: usize) -> i64 {
    if input.is_null() || (length != 9 && length != 10) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|value| *value < 0 || *value > 127) { return -1; }
    if length == 10 && values[8] != 45 { return -1; }
    let mut number = 0i64;
    for value in &values[..8] {
        if !(48..=57).contains(value) { return -1; }
        number = number * 10 + *value - 48;
    }
    let mut letter = values[length - 1];
    if (97..=122).contains(&letter) { letter -= 32; }
    if !(65..=90).contains(&letter) { return -1; }
    if letter == CHECK_LETTERS[(number % 23) as usize] as i64 { 1 } else { 0 }
}
