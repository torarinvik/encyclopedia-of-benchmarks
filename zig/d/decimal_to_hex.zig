pub export fn decimal_to_hex(value_input: i64, output: [*c]u8, capacity: usize) i64 {
    if (value_input < 0 or value_input > 9_007_199_254_740_991) return -1;
    var value = value_input;
    var width: usize = 1;
    var n = value;
    while (n >= 16) : (n = @divTrunc(n, 16)) width += 1;
    if (output == null or capacity < width) return -2;
    var position = width;
    while (position > 0) {
        position -= 1;
        const digit: u8 = @intCast(@mod(value, 16));
        output[position] = if (digit < 10) '0' + digit else 'A' + digit - 10;
        value = @divTrunc(value, 16);
    }
    return @intCast(width);
}
