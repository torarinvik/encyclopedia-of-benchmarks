/// Encode ASCII letters as their one-based alphabet positions.
export fn a1z26_cipher(input: [*c]const i64, length: usize,
                       output: [*c]u8, output_capacity: usize) i64 {
    if (length > 66) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (!((value >= 65 and value <= 90) or (value >= 97 and value <= 122))) return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| {
        const value = input[index];
        output[index] = @intCast(if (value >= 97) value - 96 else value - 64);
    }
    return @intCast(length);
}
