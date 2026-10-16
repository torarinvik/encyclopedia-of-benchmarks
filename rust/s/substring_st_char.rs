const MAX_TEXT_LENGTH: usize = 128;
const MAX_REQUESTED_COUNT: i64 = 64;
const CHECKSUM_BASE: i64 = 300_000;

#[no_mangle]
pub unsafe extern "C" fn substring_st_char(values: *const i64, length: usize) -> i64 {
    if values.is_null() || !(2..=MAX_TEXT_LENGTH + 2).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let target = input[0];
    let requested = input[1];
    let text = &input[2..];
    if target < 1 || target > 127 || requested < 0 || requested > MAX_REQUESTED_COUNT
        || text.iter().any(|&byte| !(1..=127).contains(&byte)) { return -1; }
    let Some(start) = text.iter().position(|&byte| byte == target) else { return -1; };
    let remaining = text.len() - start;
    let mut count = requested as usize;
    if count == 0 { count = 1; }
    if count > remaining { count = remaining; }
    let checksum: i64 = text[start..start + count].iter().enumerate()
        .map(|(index, &byte)| (index as i64 + 1) * byte).sum();
    count as i64 * CHECKSUM_BASE + checksum
}
