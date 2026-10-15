fn hexValue(value: i64) ?u8 {
    if (value >= 48 and value <= 57) return @intCast(value - 48);
    if (value >= 65 and value <= 70) return @intCast(value - 65 + 10);
    if (value >= 97 and value <= 102) return @intCast(value - 97 + 10);
    return null;
}

export fn hex_to_binary(values: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (length > 256 or (length != 0 and values == null)) return -1;
    for (0..length) |index| {
        if (hexValue(values.?[index]) == null) return -1;
    }

    const required = length * 4;
    if (output == null or capacity < required) return -2;
    for (0..length) |index| {
        const digit = hexValue(values.?[index]).?;
        for (0..4) |bit| {
            output.?[index * 4 + bit] = if (((digit >> @intCast(3 - bit)) & 1) == 1) '1' else '0';
        }
    }
    return @intCast(required);
}
