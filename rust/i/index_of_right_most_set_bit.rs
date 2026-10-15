const INT32_MIN_VALUE: i64 = i32::MIN as i64;
const INT32_MAX_VALUE: i64 = i32::MAX as i64;

/// Zero-based trailing set-bit index using the Java magnitude behavior.
#[no_mangle]
pub extern "C" fn index_of_right_most_set_bit(value: i64) -> i64 {
    if !(INT32_MIN_VALUE..=INT32_MAX_VALUE).contains(&value) || value == 0 {
        return -1;
    }
    let mut magnitude = (if value < 0 { -value } else { value }) as u64;
    let mut index = 0_i64;
    while magnitude & 1 == 0 {
        magnitude >>= 1;
        index += 1;
    }
    index
}
