/// Return the trailing-zero count of the signed 32-bit XOR.
#[no_mangle]
pub extern "C" fn first_different_bit(x: i64, y: i64) -> i64 {
    if x < i32::MIN as i64 || x > i32::MAX as i64 ||
       y < i32::MIN as i64 || y > i32::MAX as i64 {
        return -1;
    }
    ((x as i32) ^ (y as i32)).trailing_zeros() as i64
}
