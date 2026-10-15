/// XOR two values in the bounded unsigned 53-bit domain.
const MAX_UINT53: u64 = 9_007_199_254_740_991;
const INVALID_RESULT: i64 = -1;

#[no_mangle]
pub extern "C" fn uint53_bitwise_xor(mut n: u64, mut m: u64) -> i64 {
    if n > MAX_UINT53 || m > MAX_UINT53 {
        return INVALID_RESULT;
    }

    let mut result: u64 = 0;
    let mut bit: u64 = 1;
    while n != 0 && m != 0 {
        let n_bit = n % 2;
        let m_bit = m % 2;
        result += ((n_bit + m_bit) % 2) * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    (result + (n + m) * bit) as i64
}
