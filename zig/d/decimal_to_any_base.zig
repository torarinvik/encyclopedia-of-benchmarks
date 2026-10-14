/// Convert a nonnegative signed 64-bit value to base 2 through 36.
export fn decimal_to_any_base(input: [*]const i64, length: usize,
                              output: [*]u8, output_capacity: usize) i64 {
    if (length != 2) return -1;
    const value = input[0];
    const base = input[1];
    if (value < 0 or base < 2 or base > 36) return -1;
    var width: usize = 1;
    var remaining = value;
    while (remaining >= base) : (remaining = @divTrunc(remaining, base)) width += 1;
    if (output_capacity < width) return -2;
    var position = width;
    remaining = value;
    while (position > 0) {
        position -= 1;
        const digit = @rem(remaining, base);
        output[position] = if (digit < 10) '0' + @as(u8, @intCast(digit))
            else 'A' + @as(u8, @intCast(digit - 10));
        remaining = @divTrunc(remaining, base);
    }
    return @intCast(width);
}
