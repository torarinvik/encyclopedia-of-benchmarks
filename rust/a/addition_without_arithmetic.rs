fn signed_sum_from_bits(bits: u32) -> i64 {
    if bits <= i32::MAX as u32 { return i64::from(bits); }
    i64::from(bits) - (1i64 << 32)
}

#[no_mangle]
pub extern "C" fn addition_without_arithmetic(left_encoded: u64, right_encoded: u64) -> i64 {
    let minimum_negative = u64::MAX - i32::MAX as u64;
    let left_valid = left_encoded <= i32::MAX as u64 || left_encoded >= minimum_negative;
    let right_valid = right_encoded <= i32::MAX as u64 || right_encoded >= minimum_negative;
    if !left_valid || !right_valid { return -1; }
    let left_value = signed_sum_from_bits(left_encoded as u32);
    let right_value = signed_sum_from_bits(right_encoded as u32);
    let mut left = left_encoded as u32;
    let mut right = right_encoded as u32;
    while right != 0 {
        let carry = left & right;
        left ^= right;
        right = carry << 1;
    }
    let result = signed_sum_from_bits(left);
    if (left_value < 0) == (right_value < 0) && (result < 0) != (left_value < 0) { return -1; }
    result
}
