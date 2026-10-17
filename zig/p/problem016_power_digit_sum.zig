const MAX_DIGITS: usize = 1001;

export fn problem016_power_digit_sum(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 2) return -1;
    const base = values[0];
    const exponent = values[1];
    if (base < 0 or base > 9 or exponent < 0 or exponent > 1000) return -1;

    var digits: [MAX_DIGITS]i64 = [_]i64{0} ** MAX_DIGITS;
    var digit_count: usize = 1;
    digits[0] = base;

    var power: i64 = 1;
    while (power < exponent) : (power += 1) {
        var carry: i64 = 0;
        for (0..digit_count) |index| {
            const product = digits[index] * base + carry;
            digits[index] = @mod(product, 10);
            carry = @divTrunc(product, 10);
        }
        while (carry > 0) {
            if (digit_count >= MAX_DIGITS) return -1;
            digits[digit_count] = @mod(carry, 10);
            digit_count += 1;
            carry = @divTrunc(carry, 10);
        }
    }

    var sum: i64 = 0;
    for (0..digit_count) |index| sum += digits[index];
    return sum;
}
