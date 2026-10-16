const INVALID_RESULT: i64 = -2_147_483_649;
/// Reverse the byte order of a signed 32-bit integer.
#[no_mangle]
pub extern "C" fn endian_converter(value: i64) -> i64 {
    if value < i32::MIN as i64 || value > i32::MAX as i64 { return INVALID_RESULT; }
    (value as i32).swap_bytes() as i64
}
