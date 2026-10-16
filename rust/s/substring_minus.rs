const MAX_TEXT_LENGTH: usize = 128;
const CHECKSUM_BASE: i64 = 1_100_000;

#[no_mangle]
pub unsafe extern "C" fn substring_minus(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(1..=MAX_TEXT_LENGTH).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if input.iter().any(|&byte| !(1..=127).contains(&byte)) { return -1; }
    let selected = &input[..length - 1];
    let checksum: i64 = selected.iter().enumerate().map(|(i, &byte)| (i as i64 + 1) * byte).sum();
    selected.len() as i64 * CHECKSUM_BASE + checksum
}
