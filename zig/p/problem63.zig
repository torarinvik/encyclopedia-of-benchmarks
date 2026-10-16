export fn problem63(max_base: i64, max_power: i64) i64 {
    const base_limit = @min(max_base, 10);
    const power_limit = @min(max_power, 22);
    var count: i64 = 0;
    var base: i64 = 1;
    while (base < base_limit) : (base += 1) {
        var power: i64 = 1;
        while (power < power_limit) : (power += 1) {
            var digits = [_]i32{0} ** 32;
            digits[0] = 1;
            var length: usize = 1;
            var exponent: i64 = 0;
            while (exponent < power) : (exponent += 1) {
                var carry: i32 = 0;
                for (0..length) |index| {
                    const value = digits[index] * @as(i32, @intCast(base)) + carry;
                    digits[index] = @rem(value, 10);
                    carry = @divTrunc(value, 10);
                }
                while (carry > 0) {
                    digits[length] = @rem(carry, 10);
                    length += 1;
                    carry = @divTrunc(carry, 10);
                }
            }
            if (@as(i64, @intCast(length)) == power) count += 1;
        }
    }
    return count;
}
