#[no_mangle]
pub extern "C" fn clear_lowest_set_bit(value: i64) -> i64 {
    if value < 0 || value > i32::MAX as i64 {
        return -1;
    }
    value & (value - 1)
}
