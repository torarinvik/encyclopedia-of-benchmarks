const MAX_TEXT_LENGTH: usize = 512;
const MAX_INPUT_LENGTH: usize = MAX_TEXT_LENGTH + 2;

export fn remove_duplicate_from_string(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const text_length_value = input[0];
    if (text_length_value < 0 or text_length_value > MAX_TEXT_LENGTH) return -1;
    const text_length: usize = @intCast(text_length_value);
    if (length != 1 + text_length) return -1;

    var result: [MAX_TEXT_LENGTH]u8 = @splat(0);
    var seen: [128]bool = @splat(false);
    var result_length: usize = 0;
    for (0..text_length) |index| {
        const value = input[index + 1];
        if (value < 0 or value > 127) return -1;
        const byte: usize = @intCast(value);
        if (!seen[byte]) {
            seen[byte] = true;
            result[result_length] = @intCast(value);
            result_length += 1;
        }
    }
    if (output_capacity < result_length or (result_length != 0 and output == null)) return -2;
    for (0..result_length) |index| output[index] = result[index];
    return @intCast(result_length);
}
