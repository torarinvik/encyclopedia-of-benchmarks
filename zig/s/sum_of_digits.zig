/// Iteratively add the decimal digits of a signed 32-bit integer's magnitude.
export fn sum_of_digits(input: i64) i64 {
    if (input < -2147483648 or input > 2147483647) return -1;
    const magnitude: u32 = @intCast(if (input < 0) -input else input);
    var remaining = magnitude;
    var total: u32 = 0;
    while (remaining >= 10) {
        const next_quotient = remaining / 10;
        remaining /= 100;
        total += next_quotient + remaining;
    }
    return magnitude - 9 * total;
}
