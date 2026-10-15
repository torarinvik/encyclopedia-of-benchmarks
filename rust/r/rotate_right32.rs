/// Rotate a 32-bit word right and return its unsigned value in i64.
#[no_mangle]
pub extern "C" fn rotate_right32(value: u64, shift: u64) -> i64 {
    if value > u32::MAX as u64 || shift > i32::MAX as u64 { return -1; }
    (value as u32).rotate_right((shift % 32) as u32) as i64
}
