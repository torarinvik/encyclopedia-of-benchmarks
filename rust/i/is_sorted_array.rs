const MAX_LENGTH: usize = 100_000;
const MAX_SAFE_INTEGER: i64 = 9_007_199_254_740_991;

#[no_mangle]
pub extern "C" fn is_sorted_array(values: *const i64, length: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    let values = if length == 0 { &[] } else { unsafe { std::slice::from_raw_parts(values, length) } };
    if values.iter().any(|&value| !(-MAX_SAFE_INTEGER..=MAX_SAFE_INTEGER).contains(&value)) { return -1; }
    if values.windows(2).any(|pair| pair[0] >= pair[1]) { return 0; }
    1
}
