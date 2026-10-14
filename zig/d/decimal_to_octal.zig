/// Write the octal digits of a nonnegative signed 64-bit input.
export fn decimal_to_octal(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 0) return -1;
    var width: usize = 1;
    var remaining = value;
    while (remaining >= 8) : (remaining = @divTrunc(remaining, 8)) width += 1;
    if (output_capacity < width) return -2;
    var position = width;
    remaining = value;
    while (position > 0) {
        position -= 1;
        output[position] = '0' + @as(u8, @intCast(@rem(remaining, 8)));
        remaining = @divTrunc(remaining, 8);
    }
    return @intCast(width);
}
