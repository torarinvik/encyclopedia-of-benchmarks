#[no_mangle]
pub extern "C" fn uint53_bitwise_and(n: i64, m: i64) -> i64 {
    const MAX_UINT53: i64 = 9_007_199_254_740_991;
    if n < 0 || m < 0 || n > MAX_UINT53 || m > MAX_UINT53 {
        return -1;
    }
    let (mut left, mut right) = (n, m);
    let (mut result, mut bit) = (0i64, 1i64);
    while left != 0 && right != 0 {
        let left_bit = left % 2;
        let right_bit = right % 2;
        result += left_bit * right_bit * bit;
        left = (left - left_bit) / 2;
        right = (right - right_bit) / 2;
        bit *= 2;
    }
    result
}
