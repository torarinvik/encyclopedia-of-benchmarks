fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
    }
}

export fn decimal_expansion(values: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (values == null or length != 3) return -1;
    const input = values.?[0..length];
    const numerator = input[0];
    const denominator = input[1];
    const base = input[2];
    if (numerator < 0 or denominator < 1 or denominator > 256 or numerator > denominator or base < 2 or base > 10) return -1;

    var digits = [_]u8{0} ** 255;
    var first_seen = [_]i64{-1} ** 256;
    var digit_count: usize = 0;
    var cycle_start: i64 = -1;
    var remainder = numerator;
    while (remainder != 0 and numerator != denominator) {
        const remainder_index: usize = @intCast(remainder);
        if (first_seen[remainder_index] >= 0) {
            cycle_start = first_seen[remainder_index];
            break;
        }
        first_seen[remainder_index] = @intCast(digit_count);
        const scaled = remainder * base;
        digits[digit_count] = @intCast(@divTrunc(scaled, denominator));
        digit_count += 1;
        remainder = @rem(scaled, denominator);
    }

    const required = 24 + digit_count;
    if (output == null or capacity < required) return -2;
    const target = output.?[0..required];
    writeI64Le(target, 0, if (numerator == denominator) 1 else 0);
    writeI64Le(target, 8, @intCast(digit_count));
    writeI64Le(target, 16, cycle_start);
    @memcpy(target[24..required], digits[0..digit_count]);
    return @intCast(required);
}
