/// Bitwise inclusive OR over the Lua uint53 domain.
export fn uint53_bitwise_or(left: u64, right: u64) i64 {
    const max_uint53: u64 = 9_007_199_254_740_991;
    if (left > max_uint53 or right > max_uint53) return -1;
    var n = left;
    var m = right;
    var result: u64 = 0;
    var bit: u64 = 1;
    while (n != 0 and m != 0) {
        const n_bit = n % 2;
        const m_bit = m % 2;
        result += (1 - (1 - n_bit) * (1 - m_bit)) * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    return @intCast(result + (n + m) * bit);
}
