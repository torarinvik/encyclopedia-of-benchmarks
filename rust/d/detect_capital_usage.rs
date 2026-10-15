/// Classify capitalization by counting uppercase letters.
const MAX_LENGTH: usize = 1024;

fn is_upper(value: i64) -> bool { (65..=90).contains(&value) }
fn is_lower(value: i64) -> bool { (97..=122).contains(&value) }

#[no_mangle]
pub extern "C" fn detect_capital_usage(input: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    if length == 0 { return 1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let mut uppercase_count = 0usize;
    for &value in values {
        if !is_upper(value) && !is_lower(value) { return -1; }
        if is_upper(value) { uppercase_count += 1; }
    }
    if uppercase_count == 0 || uppercase_count == length ||
        (uppercase_count == 1 && is_upper(values[0])) { 1 } else { 0 }
}
