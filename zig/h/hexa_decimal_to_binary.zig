fn hexDigit(code: i64) ?u32 {
    if (code >= 48 and code <= 57) return @intCast(code - 48);
    if (code >= 65 and code <= 70) return @intCast(code - 55);
    if (code >= 97 and code <= 102) return @intCast(code - 87);
    return null;
}

export fn hexa_decimal_to_binary(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length == 0 or length > 65) return -1;
    var first_digit: usize = 0;
    var negative = false;
    if (input.?[0] == 45) { negative = true; first_digit = 1; }
    else if (input.?[0] == 43) first_digit = 1;
    if (first_digit == length) return -1;
    const limit: u64 = if (negative) 2_147_483_648 else 2_147_483_647;
    var value: u64 = 0;
    for (first_digit..length) |index| {
        const digit = hexDigit(input.?[index]) orelse return -1;
        if (value > (limit - digit) / 16) return -1;
        value = value * 16 + digit;
    }
    var bits: u32 = @intCast(value);
    if (negative and value != 0) bits = @intCast(4_294_967_296 - value);
    var width: usize = 0;
    var remaining = bits;
    while (remaining != 0) {
        width += 1;
        remaining >>= 1;
    }
    if (negative and value != 0) width = 32
    else if (width < 8) width = 8;
    var buffer: [32]u8 = undefined;
    remaining = bits;
    var position = width;
    while (position > 0) {
        position -= 1;
        buffer[position] = '0' + @as(u8, @intCast(remaining % 2));
        remaining /= 2;
    }
    if (width > output_capacity or output == null) return -2;
    for (0..width) |index| output.?[index] = buffer[index];
    return @intCast(width);
}
