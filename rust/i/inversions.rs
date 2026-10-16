#[no_mangle]
pub extern "C" fn inversions(values: *const i64, length: usize) -> i64 {
    if length > 1024 || (length != 0 && values.is_null()) { return -1; }
    let slice = if length == 0 { &[] } else { unsafe { std::slice::from_raw_parts(values, length) } };
    if slice.iter().any(|&x| x < i32::MIN as i64 || x > i32::MAX as i64) { return -1; }
    let mut count = 0i64;
    for i in 0..length { for j in i + 1..length { if slice[i] > slice[j] { count += 1; } } }
    count
}
