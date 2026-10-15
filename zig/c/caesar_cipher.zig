/// Apply a normalized Caesar shift to ASCII letters in a byte sequence.
export fn caesar_cipher(input: [*c]const i64, length: usize,
                        output: [*c]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 66) return -1;
    const text_length = length - 1;
    for (0..text_length) |index| {
        const value = input[index];
        if (value < 0 or value > 127) return -1;
    }
    if (output_capacity < text_length) return -2;

    var shift = @rem(input[text_length], 26);
    if (shift < 0) shift += 26;
    for (0..text_length) |index| {
        const value = input[index];
        var mapped = value;
        if (value >= 65 and value <= 90) {
            mapped = 65 + @as(i64, @intCast(@mod(value - 65 + shift, 26)));
        } else if (value >= 97 and value <= 122) {
            mapped = 97 + @as(i64, @intCast(@mod(value - 97 + shift, 26)));
        }
        output[index] = @intCast(mapped);
    }
    return @intCast(text_length);
}
