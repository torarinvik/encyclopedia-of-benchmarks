/// Apply ROT13 only to lowercase non-NUL ASCII bytes.
export fn theoretical_rot13(input: [*c]const i64, length: usize,
                            output: [*c]u8, output_capacity: usize) i64 {
    if (length > 66) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < 1 or value > 127) return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| {
        const value = input[index];
        const mapped = if (value >= 'a' and value <= 'z')
            'a' + @mod(value - 'a' + 13, 26)
        else
            value;
        output[index] = @intCast(mapped);
    }
    return @intCast(length);
}
