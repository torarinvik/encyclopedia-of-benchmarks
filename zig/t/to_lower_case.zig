/// Lowercase ASCII bytes without locale-dependent character handling.
const MAX_LENGTH: usize = 4096;

export fn to_lower_case(input: [*c]const i64, length: usize,
                        output: [*c]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < 1 or value > 127) return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| {
        var value = input[index];
        if (value >= 65 and value <= 90) value += 32;
        output[index] = @intCast(value);
    }
    return @intCast(length);
}
