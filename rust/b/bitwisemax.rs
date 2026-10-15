/// Select the larger signed-32-bit nonnegative value with a sign bit.
#[no_mangle]
pub extern "C" fn bitwisemax(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 2 { return -1; }
    let left = unsafe { *values };
    let right = unsafe { *values.add(1) };
    if !(0..=i32::MAX as i64).contains(&left) || !(0..=i32::MAX as i64).contains(&right) {
        return -1;
    }
    let difference = left - right;
    let choose_right = ((difference as u32) >> 31) as i64;
    left - choose_right * difference
}
