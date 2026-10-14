/// Write lowercase hexadecimal digits of a nonnegative signed 64-bit input.
export fn decimal_to_hexadecimal(value: i64, output: [*]u8, output_capacity: usize) i64 {
    if (value < 0) return -1;
    var width: usize = 1;
    var remaining = value;
    while (remaining >= 16) : (remaining = @divTrunc(remaining, 16)) width += 1;
    if (output_capacity < width) return -2;
    var position = width;
    remaining = value;
    while (position > 0) {
        position -= 1;
        const digit: u8 = @intCast(@rem(remaining, 16));
        output[position] = if (digit < 10) '0' + digit else 'a' + digit - 10;
        remaining = @divTrunc(remaining, 16);
    }
    return @intCast(width);
}
