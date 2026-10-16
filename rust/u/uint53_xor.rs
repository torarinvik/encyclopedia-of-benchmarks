/// Iterative bitwise XOR for two nonnegative integers in the exact uint53 range.
const MAX_UINT53: i64 = 9_007_199_254_740_991;

#[no_mangle]
pub extern "C" fn uint53_xor(mut left: i64, mut right: i64) -> i64 {
    if !(0..=MAX_UINT53).contains(&left) || !(0..=MAX_UINT53).contains(&right) { return -1; }
    let mut result = 0i64;
    let mut bit = 1i64;
    while left != 0 && right != 0 {
        let left_bit = left % 2;
        let right_bit = right % 2;
        result += ((left_bit + right_bit) % 2) * bit;
        left = (left - left_bit) / 2;
        right = (right - right_bit) / 2;
        bit *= 2;
    }
    result + (left + right) * bit
}
