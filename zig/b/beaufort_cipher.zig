export fn beaufort_cipher(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > 2051) return -1;
    const mode = input[0];
    const text_length_value = input[1];
    const key_length_value = input[2];
    if ((mode != 0 and mode != 1) or text_length_value < 0 or text_length_value > 1024 or
        key_length_value < 0 or key_length_value > 1024) return -1;
    const text_length: usize = @intCast(text_length_value);
    const key_length: usize = @intCast(key_length_value);
    if (length != 3 + text_length + key_length or
        (text_length == 0 and key_length != 0) or
        (text_length != 0 and (key_length == 0 or key_length > text_length))) return -1;
    const key_start = 3 + text_length;
    for (0..text_length) |index| {
        const value = input[3 + index];
        if (value != ' ' and (value < 'A' or value > 'Z')) return -1;
    }
    for (0..key_length) |index| if (input[key_start + index] < 'A' or input[key_start + index] > 'Z') return -1;
    if (output_capacity < text_length or (text_length != 0 and output == null)) return -2;
    var key_index: usize = 0;
    for (0..text_length) |index| {
        const value = input[3 + index];
        if (value == ' ') { output[index] = ' '; continue; }
        const letter = value - 'A';
        const key = input[key_start + key_index % key_length] - 'A';
        const mapped = if (mode == 0) @mod(letter - key + 26, 26) else @mod(letter + key, 26);
        output[index] = @intCast('A' + mapped);
        key_index += 1;
    }
    return @intCast(text_length);
}
