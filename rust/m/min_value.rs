#[no_mangle]
pub extern "C" fn min_value(a: i64, b: i64) -> i64 {
    if a < i32::MIN as i64 || a > i32::MAX as i64 || b < i32::MIN as i64 || b > i32::MAX as i64 { return -1; }
    if a <= b { a } else { b }
}
