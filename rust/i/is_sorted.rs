#[no_mangle]
pub extern "C" fn is_sorted(values: *const i64, length: usize) -> i64 {
    if length > 4096 || (length != 0 && values.is_null()) { return -1; }
    if length == 0 { return 1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values.iter().any(|&value| !(-2_147_483_648..=2_147_483_647).contains(&value)) { return -1; }
    if values.windows(2).any(|pair| pair[0] > pair[1]) { 0 } else { 1 }
}
