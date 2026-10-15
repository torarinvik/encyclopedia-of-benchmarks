/// Multiply a base-10 digit array by each factor through n.
const MAX_N: i64 = 100;
const MAX_DIGITS: usize = 160;

export fn factorial_large_number(n: i64, output: [*]u8, output_capacity: usize) i64 {
    if (n < 0 or n > MAX_N) return -1;
    var digits: [MAX_DIGITS]i64 = @splat(0);
    digits[0] = 1;
    var digit_count: usize = 1;
    var factor: i64 = 2;
    while (factor <= n) : (factor += 1) {
        var carry: i64 = 0;
        for (0..digit_count) |index| {
            const product = digits[index] * factor + carry;
            digits[index] = @mod(product, 10);
            carry = @divTrunc(product, 10);
        }
        while (carry != 0) {
            digits[digit_count] = @mod(carry, 10);
            digit_count += 1;
            carry = @divTrunc(carry, 10);
        }
    }
    if (output_capacity < digit_count) return -2;
    for (0..digit_count) |index| {
        output[index] = @intCast(48 + digits[digit_count - index - 1]);
    }
    return @intCast(digit_count);
}
