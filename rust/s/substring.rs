const MAX_TEXT_LENGTH: usize = 128;
const MAX_REQUESTED_COUNT: i64 = 64;
const CHECKSUM_BASE: i64 = 300_000;

#[no_mangle]
pub unsafe extern "C" fn substring(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=MAX_TEXT_LENGTH + 2).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let text_length = length - 2;
    let start = input[0];
    let requested = input[1];
    if start < 0 || start as usize > text_length || requested < 0 || requested > MAX_REQUESTED_COUNT { return -1; }
    let text = &input[2..];
    if text.iter().any(|&byte| !(1..=127).contains(&byte)) { return -1; }
    let remaining = text_length - start as usize;
    let mut count = requested as usize;
    if count == 0 && remaining > 0 { count = 1; }
    if count > remaining { count = remaining; }
    let checksum: i64 = text[start as usize..start as usize + count].iter().enumerate()
        .map(|(index, &byte)| (index as i64 + 1) * byte).sum();
    count as i64 * CHECKSUM_BASE + checksum
}
