/// Convert a most-significant-first bit array to radix 8 text.
export fn binary_to_octal(bits: [*]const i64, length: usize,
                     output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 63) return -1;
    var value: i64 = 0;
    for (0..length) |index| {
        const bit = bits[index];
        if (bit < 0 or bit > 1) return -1;
        value = value * 2 + bit;
    }
    var width: usize = 1;
    var remaining = value;
    while (remaining >= 8) : (remaining = @divTrunc(remaining, 8)) width += 1;
    if (output_capacity < width) return -2;
    var position = width;
    remaining = value;
    while (position > 0) {
        position -= 1;
        const digit = @rem(remaining, 8);
        output[position] = if (digit < 10) '0' + @as(u8, @intCast(digit))
            else 'a' + @as(u8, @intCast(digit - 10));
        remaining = @divTrunc(remaining, 8);
    }
    return @intCast(width);
}
