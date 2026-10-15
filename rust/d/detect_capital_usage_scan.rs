/// Recheck the whole word for every uppercase byte after the first.
const MAX_LENGTH: usize = 1024;

fn is_upper(value: i64) -> bool { (65..=90).contains(&value) }
fn is_lower(value: i64) -> bool { (97..=122).contains(&value) }

#[no_mangle]
pub extern "C" fn detect_capital_usage_scan(input: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    if length == 0 { return 1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    for &value in values {
        if !is_upper(value) && !is_lower(value) { return -1; }
    }
    for index in 1..length {
        if is_upper(values[index]) && values.iter().any(|&value| is_lower(value)) {
            return 0;
        }
    }
    1
}
