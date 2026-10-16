const MAX_INPUT_LENGTH: usize = 4096;
fn lower_ascii(c: u8) -> u8 { if c.is_ascii_uppercase() { c + 32 } else { c } }
fn vowel(c: u8) -> bool { matches!(c, b'a' | b'e' | b'i' | b'o' | b'u') }

#[no_mangle]
pub unsafe extern "C" fn remove_vowels(values: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 1 || length > MAX_INPUT_LENGTH + 1 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input[0] < 0 || input[0] as usize > MAX_INPUT_LENGTH || length != input[0] as usize + 1 { return -1; }
    let text = &input[1..];
    if text.iter().any(|&x| !(0..=127).contains(&x)) { return -1; }
    let result = text.iter().filter(|&&x| !vowel(lower_ascii(x as u8))).count();
    if result > capacity || (result > 0 && output.is_null()) { return -2; }
    let mut written = 0;
    for &x in text { let c = lower_ascii(x as u8); if !vowel(c) { *output.add(written) = c; written += 1; } }
    written as i64
}
