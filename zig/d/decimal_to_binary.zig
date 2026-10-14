/// Write the most-significant-first binary representation of a nonnegative i64.
export fn decimal_to_binary(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 0) return -1;

    var width: usize = 1;
    var remaining = value;
    while (remaining > 1) : (remaining = @divTrunc(remaining, 2)) {
        width += 1;
    }
    if (output_capacity < width) return -2;

    var position = width;
    remaining = value;
    while (position > 0) {
        position -= 1;
        output[position] = '0' + @as(u8, @intCast(@rem(remaining, 2)));
        remaining = @divTrunc(remaining, 2);
    }
    return @intCast(width);
}
