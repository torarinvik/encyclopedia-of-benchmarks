/// Reduce the input array to its minimum with a sign-bit mask.
#[no_mangle]
pub extern "C" fn bitwisemin(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > 4096 { return -1; }
    let mut minimum = unsafe { *values };
    if !(0..=i32::MAX as i64).contains(&minimum) { return -1; }
    for index in 1..length {
        let value = unsafe { *values.add(index) };
        if !(0..=i32::MAX as i64).contains(&value) { return -1; }
        let difference = minimum - value;
        let sign = ((difference as u32) >> 31) & 1;
        let keep_minimum = 0_u32.wrapping_sub(sign);
        minimum = ((minimum as u32 & keep_minimum) | (value as u32 & !keep_minimum)) as i64;
    }
    minimum
}
