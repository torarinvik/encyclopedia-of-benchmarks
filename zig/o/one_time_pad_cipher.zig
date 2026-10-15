const MAX_TEXT_LENGTH: usize = 1024;

export fn one_time_pad_cipher(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 2 + 2 * MAX_TEXT_LENGTH) return -1;
    const mode = input[0];
    const count_value = input[1];
    if ((mode != 0 and mode != 1) or count_value < 0 or count_value > MAX_TEXT_LENGTH) return -1;
    const count: usize = @intCast(count_value);
    if (length != 2 + 2 * count) return -1;
    if (output_capacity < count) return -2;
    for (0..count) |index| {
        const data = input[2 + index];
        const key = input[2 + count + index];
        if (data < 0 or data > 255 or key < 0 or key > 255) return -1;
        output[index] = @intCast(data ^ key);
    }
    return @intCast(count);
}
