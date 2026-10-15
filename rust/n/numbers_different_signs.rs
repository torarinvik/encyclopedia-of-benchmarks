const INT32_MIN_VALUE: i64 = i32::MIN as i64;
const INT32_MAX_VALUE: i64 = i32::MAX as i64;

/// Return whether the signed 32-bit XOR has its sign bit set.
#[no_mangle]
pub extern "C" fn numbers_different_signs(left: i64, right: i64) -> i64 {
    if left < INT32_MIN_VALUE || left > INT32_MAX_VALUE ||
       right < INT32_MIN_VALUE || right > INT32_MAX_VALUE {
        return -1;
    }
    if ((left as i32) ^ (right as i32)) < 0 { 1 } else { 0 }
}
