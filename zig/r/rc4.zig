const MAX_INPUT_VALUES: usize = 515;

export fn rc4(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    const key_length_value = values[0];
    const plaintext_length_value = values[1];
    if (key_length_value < 1 or key_length_value > 256) return -1;
    if (plaintext_length_value < 0 or plaintext_length_value > 256) return -1;
    const key_length: usize = @intCast(key_length_value);
    const plaintext_length: usize = @intCast(plaintext_length_value);
    if (length != 2 + key_length + plaintext_length) return -1;
    for (values[2..]) |value| {
        if (value < 0 or value > 255) return -1;
    }
    if (plaintext_length == 0) return 0;
    if (output == null or capacity < plaintext_length) return -2;

    var state: [256]u8 = @splat(0);
    for (0..256) |index| state[index] = @intCast(index);
    var j: usize = 0;
    for (0..256) |index| {
        j = (j + @as(usize, state[index]) + @as(usize, @intCast(values[2 + index % key_length]))) & 255;
        const temporary = state[index];
        state[index] = state[j];
        state[j] = temporary;
    }

    var i: usize = 0;
    j = 0;
    for (0..plaintext_length) |offset| {
        i = (i + 1) & 255;
        j = (j + @as(usize, state[i])) & 255;
        const temporary = state[i];
        state[i] = state[j];
        state[j] = temporary;
        const stream_index = (@as(usize, state[i]) + @as(usize, state[j])) & 255;
        const plaintext: u8 = @intCast(values[2 + key_length + offset]);
        output.?[offset] = plaintext ^ state[stream_index];
    }
    return @intCast(plaintext_length);
}
