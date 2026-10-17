export fn tokenize_string(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130) return -1;
    if (input[0] < 0 or input[0] > 128) return -1;
    const text_length: usize = @intCast(input[0]);
    if (length != 2 + text_length) return -1;
    const separator = input[1];
    if (separator != 44 and separator != 46 and separator != 58) return -1;
    var separator_count: usize = 0;
    for (0..text_length) |index| {
        const byte = input[index + 2];
        if (byte < 32 or byte > 126) return -1;
        if (byte == separator) separator_count += 1;
    }
    if (separator_count > 18) return -1;
    const output_length = text_length + 2;
    if (output == null or capacity < output_length) return -2;
    output[0] = @intCast(separator_count + 1);
    for (0..text_length) |index|
        output[index + 1] = if (input[index + 2] == separator) 0 else @intCast(input[index + 2]);
    output[output_length - 1] = 0;
    return @intCast(output_length);
}
