const MAX_WORD_BYTES: usize = 64;
fn upper_ascii(c: u32) -> u32 { if (97..=122).contains(&c) { c - 32 } else { c } }
#[no_mangle]
pub unsafe extern "C" fn cbench_ispell_hash(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > MAX_WORD_BYTES + 1 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(values, length) };
    let table_size = input[0];
    if !(1..=2_147_483_647).contains(&table_size) { return -1; }
    let word = &input[1..];
    if word.iter().any(|&c| !(1..=127).contains(&c)) { return -1; }
    let mut h: u32 = 0;
    let initial = word.len().min(4);
    for &c in &word[..initial] { h = (h << 8) | upper_ascii(c as u32); }
    for &c in &word[initial..] { h = h.rotate_left(5) ^ upper_ascii(c as u32); }
    (u64::from(h) % table_size as u64) as i64
}
