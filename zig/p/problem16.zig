export fn problem16(exponent: i64) i64 {
    if (exponent < 0 or exponent > 1000) return -1;
    var digits = [_]i64{0} ** 400;
    digits[0] = 1;
    var length: usize = 1;
    var power: i64 = 0;
    while (power < exponent) : (power += 1) {
        var carry: i64 = 0;
        for (0..length) |index| {
            const value = digits[index] * 2 + carry;
            digits[index] = @rem(value, 10);
            carry = @divTrunc(value, 10);
        }
        while (carry > 0) {
            digits[length] = @rem(carry, 10);
            length += 1;
            carry = @divTrunc(carry, 10);
        }
    }
    var sum: i64 = 0;
    for (0..length) |index| sum += digits[index];
    return sum;
}
