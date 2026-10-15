/// Return the zero-based index of the most significant set bit.
#[no_mangle]
pub extern "C" fn highest_set_bit(value: i64) -> i64 {
    if value <= 0 {
        return -1;
    }
    let mut remaining = value as u64;
    let mut position = 0;
    while remaining > 1 {
        remaining >>= 1;
        position += 1;
    }
    position
}
