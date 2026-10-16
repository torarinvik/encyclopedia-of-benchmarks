/// Return whether two signed 32-bit values differ in exactly one bit.
#[no_mangle]
pub unsafe extern "C" fn one_bit_difference(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let left = values[0];
    let right = values[1];
    if left < i32::MIN as i64 || left > i32::MAX as i64 || right < i32::MIN as i64 || right > i32::MAX as i64 { return -1; }
    let difference = (left as i32 as u32) ^ (right as i32 as u32);
    i64::from(difference != 0 && (difference & (difference - 1)) == 0)
}
