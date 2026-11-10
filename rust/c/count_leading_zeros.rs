#[no_mangle]
pub extern "C" fn count_leading_zeros(value: i64) -> i64 {
    if value < i32::MIN as i64 || value > i32::MAX as i64 {
        return -1;
    }
    (value as u32).leading_zeros() as i64
}
