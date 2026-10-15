/// Overflow-safe floor arithmetic mean using the bitwise identity.
#[no_mangle]
pub extern "C" fn arithmeticmean(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let left = unsafe { *values };
    let right = unsafe { *values.add(1) };
    if !(0..=9_000_000_000_000_000_000).contains(&left)
        || !(0..=9_000_000_000_000_000_000).contains(&right) {
        return -1;
    }
    ((left ^ right) >> 1) + (left & right)
}
