/// Decode one-based alphabet positions as lowercase ASCII letters.
export fn a1z26_decipher(input: [*c]const i64, length: usize,
                         output: [*c]u8, output_capacity: usize) i64 {
    if (length > 66) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < 1 or value > 26) return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| output[index] = @intCast(96 + input[index]);
    return @intCast(length);
}
