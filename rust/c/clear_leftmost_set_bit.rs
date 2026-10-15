#[no_mangle]
pub extern "C" fn clear_leftmost_set_bit(value: i64) -> i64 {
    if value < 0 || value > i32::MAX as i64 {
        return -1;
    }
    if value == 0 {
        return 0;
    }
    let mut temp = value;
    let mut position = 0u32;
    while temp > 0 {
        temp >>= 1;
        position += 1;
    }
    let mask = !(1i64 << (position - 1));
    value & mask
}
