/// Alphabetic Vernam cipher with a repeating key and modulo-26 arithmetic.
const max_vernam_length = 1024;

export fn vernam_cipher(input: [*]const i64, length: usize,
                        output: [*]u8, output_capacity: usize) i64 {
    if (length < 3 or length > 2051) return -1;
    const mode = input[0];
    const text_length_value = input[1];
    const key_length_value = input[2];
    if ((mode != 0 and mode != 1) or text_length_value < 0 or text_length_value > max_vernam_length
        or key_length_value < 1 or key_length_value > max_vernam_length) return -1;
    const text_length: usize = @intCast(text_length_value);
    const key_length: usize = @intCast(key_length_value);
    if (length != 3 + text_length + key_length) return -1;
    const key_start = 3 + text_length;
    for (0..text_length) |index| if (input[3 + index] < 'A' or input[3 + index] > 'Z') return -1;
    for (0..key_length) |index| if (input[key_start + index] < 'A' or input[key_start + index] > 'Z') return -1;
    if (output_capacity < text_length) return -2;

    for (0..text_length) |index| {
        const text_value = input[3 + index] - 'A';
        const key_value = input[key_start + index % key_length] - 'A';
        const mapped = if (mode == 0) @mod(text_value + key_value, 26)
                       else @mod(text_value - key_value + 26, 26);
        output[index] = @intCast('A' + mapped);
    }
    return @intCast(text_length);
}
