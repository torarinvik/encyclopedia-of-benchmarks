/// Apply case-preserving ROT13 to a non-NUL ASCII byte sequence.
export fn rot13(input: [*c]const i64, length: usize,
                output: [*c]u8, output_capacity: usize) i64 {
    if (length > 66) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < 1 or value > 127) return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| {
        const value = input[index];
        var mapped = value;
        if (value >= 'A' and value <= 'Z') {
            mapped = 'A' + @as(i64, @intCast(@mod(value - 'A' + 13, 26)));
        } else if (value >= 'a' and value <= 'z') {
            mapped = 'a' + @as(i64, @intCast(@mod(value - 'a' + 13, 26)));
        }
        output[index] = @intCast(mapped);
    }
    return @intCast(length);
}
