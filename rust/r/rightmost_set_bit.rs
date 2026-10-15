/// Return the one-based position of the least significant set bit.
#[no_mangle]
pub extern "C" fn rightmost_set_bit(value: i64) -> i64 {
    if value <= 0 || value > i32::MAX as i64 {
        return -1;
    }
    let lowest = (value as u32) & (0u32.wrapping_sub(value as u32));
    lowest.trailing_zeros() as i64 + 1
}
