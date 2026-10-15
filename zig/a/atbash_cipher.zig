/// Apply the case-preserving Atbash mapping to a 7-bit ASCII byte sequence.
export fn atbash_cipher(input: [*c]const i64, length: usize,
                        output: [*c]u8, output_capacity: usize) i64 {
    if (length > 66) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (value < 0 or value > 127) return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| {
        const value = input[index];
        var mapped = value;
        if (value >= 65 and value <= 90) {
            mapped = 155 - value;
        } else if (value >= 97 and value <= 122) {
            mapped = 219 - value;
        }
        output[index] = @intCast(mapped);
    }
    return @intCast(length);
}
