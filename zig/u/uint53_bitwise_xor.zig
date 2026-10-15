/// XOR two values in the bounded unsigned 53-bit domain.
const MAX_UINT53: u64 = 9_007_199_254_740_991;
const INVALID_RESULT: i64 = -1;

export fn uint53_bitwise_xor(n: u64, m: u64) i64 {
    if (n > MAX_UINT53 or m > MAX_UINT53) return INVALID_RESULT;

    var current_n = n;
    var current_m = m;
    var result: u64 = 0;
    var bit: u64 = 1;
    while (current_n != 0 and current_m != 0) {
        const n_bit = @mod(current_n, 2);
        const m_bit = @mod(current_m, 2);
        result += @mod(n_bit + m_bit, 2) * bit;
        current_n = @divTrunc(current_n - n_bit, 2);
        current_m = @divTrunc(current_m - m_bit, 2);
        bit *= 2;
    }
    return @intCast(result + (current_n + current_m) * bit);
}
