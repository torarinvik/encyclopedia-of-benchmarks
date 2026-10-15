export fn porta_cipher(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > 1091) return -1;
    const mode = input[0];
    const text_value = input[1];
    const key_value = input[2];
    if ((mode != 0 and mode != 1) or text_value < 0 or text_value > 1024 or key_value < 0 or key_value > 64) return -1;
    const text_length: usize = @intCast(text_value);
    const key_length: usize = @intCast(key_value);
    if (length != 3 + text_length + key_length or (text_length != 0 and key_length == 0)) return -1;
    const key_start = 3 + text_length;
    for (3..length) |index| {
        const value = input[index];
        if (!((value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z'))) return -1;
    }
    if (output_capacity < text_length or (text_length != 0 and output == null)) return -2;
    for (0..text_length) |index| {
        var letter = input[3 + index];
        var key_letter = input[key_start + index % key_length];
        if (letter >= 'a') letter -= 32;
        if (key_letter >= 'a') key_letter -= 32;
        const letter_index = letter - 'A';
        const group = (key_letter - 'A') / 2;
        const mapped = if (letter_index < 13) 13 + @mod(letter_index + 13 - group, 13)
                       else @mod(letter_index - 13 + group, 13);
        output[index] = @intCast('A' + mapped);
    }
    return @intCast(text_length);
}
