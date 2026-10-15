/// Encrypt ASCII text with a repeating, case-insensitive Vigenere key.
export fn vigenere_cipher(input: [*c]const i64, length: usize,
                          output: [*c]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 66) return -1;
    var separator: usize = 0;
    while (separator < length and input[separator] != 0) : (separator += 1) {}
    if (separator == length or separator + 1 == length) return -1;
    const key_length = length - separator - 1;
    for (0..separator) |index| {
        const value = input[index];
        if (value < 1 or value > 127) return -1;
    }
    for (0..key_length) |index| {
        const value = input[separator + 1 + index];
        if (!((value >= 65 and value <= 90) or (value >= 97 and value <= 122))) return -1;
    }
    if (output_capacity < separator) return -2;

    var key_index: usize = 0;
    for (0..separator) |index| {
        const value = input[index];
        var mapped = value;
        if (value >= 65 and value <= 90) {
            var key_value = input[separator + 1 + key_index];
            if (key_value >= 97) key_value -= 32;
            mapped = 65 + @mod(value - 65 + key_value - 65, 26);
            key_index = (key_index + 1) % key_length;
        } else if (value >= 97 and value <= 122) {
            var key_value = input[separator + 1 + key_index];
            if (key_value <= 90) key_value += 32;
            mapped = 97 + @mod(value - 97 + key_value - 97, 26);
            key_index = (key_index + 1) % key_length;
        }
        output[index] = @intCast(mapped);
    }
    return @intCast(separator);
}
