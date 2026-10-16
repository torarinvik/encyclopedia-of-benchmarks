/// Encrypt ASCII letters with a repeating decimal-digit Gronsfeld key.
export fn gronsfeld(input: [*c]const i64, length: usize,
                    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 321) return -1;
    var separator: usize = 0;
    while (separator < length and input[separator] != 0) : (separator += 1) {}
    if (separator == length) return -1;
    const text_length = separator;
    const key_length = length - separator - 1;
    if (text_length > 256 or key_length < 1 or key_length > 64) return -1;

    for (0..text_length) |index| {
        const value = input[index];
        if (value < 1 or value > 127) return -1;
    }
    for (0..key_length) |index| {
        const value = input[separator + 1 + index];
        if (value < 48 or value > 57) return -1;
    }
    if (output_capacity < text_length or (text_length > 0 and output == null)) return -2;

    var key_index: usize = 0;
    for (0..text_length) |index| {
        const value = input[index];
        var mapped = value;
        if (value >= 65 and value <= 90) {
            const shift = input[separator + 1 + key_index % key_length] - 48;
            mapped = 65 + @mod(value - 65 + shift, 26);
            key_index += 1;
        } else if (value >= 97 and value <= 122) {
            const shift = input[separator + 1 + key_index % key_length] - 48;
            mapped = 97 + @mod(value - 97 + shift, 26);
            key_index += 1;
        }
        output[index] = @intCast(mapped);
    }
    return @intCast(text_length);
}
