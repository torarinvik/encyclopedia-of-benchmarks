/// Convert a most-significant-first octal digit array to radix 16 text.
export fn octal_to_hexadecimal(digits: [*]const i64, length: usize,
                     output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 21) return -1;
    var value: i64 = 0;
    for (0..length) |index| {
        const octal_digit = digits[index];
        if (octal_digit < 0 or octal_digit > 7) return -1;
        value = value * 8 + octal_digit;
    }
    var width: usize = 1;
    var remaining = value;
    while (remaining >= 16) : (remaining = @divTrunc(remaining, 16)) width += 1;
    if (output_capacity < width) return -2;
    var position = width;
    remaining = value;
    while (position > 0) {
        position -= 1;
        const digit = @rem(remaining, 16);
        output[position] = if (digit < 10) '0' + @as(u8, @intCast(digit))
            else 'a' + @as(u8, @intCast(digit - 10));
        remaining = @divTrunc(remaining, 16);
    }
    return @intCast(width);
}
