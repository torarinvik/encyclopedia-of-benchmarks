/// Bitwise inclusive OR over the Lua uint53 domain.
#[no_mangle]
pub extern "C" fn uint53_bitwise_or(left: u64, right: u64) -> i64 {
    const MAX_UINT53: u64 = 9_007_199_254_740_991;
    if left > MAX_UINT53 || right > MAX_UINT53 { return -1; }
    let (mut n, mut m) = (left, right);
    let (mut result, mut bit) = (0u64, 1u64);
    while n != 0 && m != 0 {
        let (n_bit, m_bit) = (n % 2, m % 2);
        result += (1 - (1 - n_bit) * (1 - m_bit)) * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    (result + (n + m) * bit) as i64
}
