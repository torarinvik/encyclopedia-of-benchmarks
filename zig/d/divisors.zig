/// Encode the source divisor list in a lossless positive signed-i64 bit mask.
export fn divisors(values: ?[*]const i64, length: usize) i64 {
    if (length != 1) return -1;
    const input = values orelse return -1;
    const n = input[0];
    if (n < 1 or n > 62) return -1;
    var mask: u64 = 0;
    var divisor: i64 = 1;
    while (divisor <= n) : (divisor += 1) {
        if (@mod(n, divisor) == 0) mask |= @as(u64, 1) << @intCast(divisor);
    }
    return @intCast(mask);
}
