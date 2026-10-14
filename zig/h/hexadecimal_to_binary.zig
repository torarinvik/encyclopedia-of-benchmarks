/// Convert a most-significant-first hexadecimal digit array to radix 2 text.
export fn hexadecimal_to_binary(digits: [*]const i64, length: usize,
                     output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 16) return -1;
    if (length == 16 and digits[0] > 7) return -1;
    var value: i64 = 0;
    for (0..length) |index| {
        const hex_digit = digits[index];
        if (hex_digit < 0 or hex_digit > 15) return -1;
        value = value * 16 + hex_digit;
    }
    var width: usize = 1;
    var remaining = value;
    while (remaining >= 2) : (remaining = @divTrunc(remaining, 2)) width += 1;
    if (output_capacity < width) return -2;
    var position = width;
    remaining = value;
    while (position > 0) {
        position -= 1;
        const digit = @rem(remaining, 2);
        output[position] = if (digit < 10) '0' + @as(u8, @intCast(digit))
            else 'a' + @as(u8, @intCast(digit - 10));
        remaining = @divTrunc(remaining, 2);
    }
    return @intCast(width);
}
