export fn problem20(n: i64) i64 {
    if (n < 0 or n > 100) return -1;
    var digits = [_]i64{0} ** 200;
    digits[0] = 1;
    var length: usize = 1;
    var factor: i64 = 2;
    while (factor <= n) : (factor += 1) {
        var carry: i64 = 0;
        for (0..length) |index| {
            const value = digits[index] * factor + carry;
            digits[index] = @mod(value, 10);
            carry = @divTrunc(value, 10);
        }
        while (carry > 0) {
            digits[length] = @mod(carry, 10);
            length += 1;
            carry = @divTrunc(carry, 10);
        }
    }
    var sum: i64 = 0;
    for (0..length) |index| sum += digits[index];
    return sum;
}
