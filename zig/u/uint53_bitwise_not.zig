/// Complement every bit in the fixed-width unsigned 53-bit domain.
const MAX_UINT53: i64 = 9_007_199_254_740_991;
const TWO_TO_53: i64 = 9_007_199_254_740_992;

export fn uint53_bitwise_not(n: i64) i64 {
    if (n < 0 or n > MAX_UINT53) return -1;

    var current = n;
    var result: i64 = 0;
    var bit: i64 = 1;
    while (current >= 255) {
        const byte = @mod(current, 256);
        result += (255 - byte) * bit;
        current = @divTrunc(current - byte, 256);
        bit *= 256;
    }
    while (current != 0) {
        const n_bit = @mod(current, 2);
        result += (1 - n_bit) * bit;
        current = @divTrunc(current - n_bit, 2);
        bit *= 2;
    }

    return TWO_TO_53 - bit + result;
}
