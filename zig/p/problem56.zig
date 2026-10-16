fn multiplyDigits(digits: *[512]u8, length: usize, factor: usize) usize {
    var carry: usize = 0;
    for (0..length) |i| { const value = @as(usize, digits[i]) * factor + carry; digits[i] = @intCast(value % 10); carry = value / 10; }
    var count = length;
    while (carry > 0) { digits[count] = @intCast(carry % 10); count += 1; carry /= 10; }
    return count;
}
export fn problem56(a: i64, b: i64) i64 {
    if (a < 1 or a > 200 or b < 1 or b > 200) return -1;
    var best: i64 = 0;
    var base: i64 = 0;
    while (base < a) : (base += 1) {
        var digits = [_]u8{0} ** 512; digits[0] = 1;
        var length: usize = 1;
        var power: i64 = 0;
        while (power < b) : (power += 1) {
            var sum: i64 = 0;
            for (0..length) |i| sum += digits[i];
            if (sum > best) best = sum;
            if (power + 1 < b) length = multiplyDigits(&digits, length, @intCast(base));
        }
    }
    return best;
}
