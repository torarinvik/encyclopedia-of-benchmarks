const MAX_BUFFER_LENGTH: i64 = 64;
const MAX_INPUT_VALUES: usize = 66;

export fn iso10126_d2_padding(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const mode = input[0];
    if (mode == 0) {
        if (length < 3) return -1;
        const offset_arg = input[1];
        const buffer_length_arg = input[2];
        if (buffer_length_arg < 1 or buffer_length_arg > MAX_BUFFER_LENGTH or
            offset_arg < 0 or offset_arg >= buffer_length_arg) return -1;
        const offset: usize = @intCast(offset_arg);
        const buffer_length: usize = @intCast(buffer_length_arg);
        const random_count = buffer_length - offset - 1;
        if (length != 3 + offset + random_count) return -1;
        for (3..length) |i| {
            if (input[i] < 0 or input[i] > 255) return -1;
        }
        for (3 + offset..length) |i| {
            if (input[i] >= 255) return -1;
        }
        const output_bytes = buffer_length + 1;
        if (output == null or capacity < output_bytes) return -2;
        const out = output.?;
        const padding_count: u8 = @intCast(buffer_length - offset);
        out[0] = padding_count;
        var position: usize = 1;
        for (0..offset) |i| {
            out[position] = @intCast(input[3 + i]);
            position += 1;
        }
        for (3 + offset..length) |i| {
            out[position] = @intCast(input[i]);
            position += 1;
        }
        out[position] = padding_count;
        return @intCast(output_bytes);
    }

    if ((mode != 1 and mode != 2) or length < 3) return -1;
    const buffer_length_arg = input[1];
    if (buffer_length_arg < 1 or buffer_length_arg > MAX_BUFFER_LENGTH) return -1;
    const buffer_length: usize = @intCast(buffer_length_arg);
    if (length != 2 + buffer_length) return -1;
    for (2..length) |i| {
        if (input[i] < 0 or input[i] > 255) return -1;
    }
    const padding_count_arg = input[length - 1];
    if (padding_count_arg < 1 or padding_count_arg > buffer_length_arg) return -1;
    const padding_count: usize = @intCast(padding_count_arg);
    const output_bytes: usize = if (mode == 1) buffer_length - padding_count else 1;
    if (output == null or capacity < output_bytes) return -2;
    const out = output.?;
    if (mode == 1) {
        for (0..output_bytes) |i| out[i] = @intCast(input[2 + i]);
    } else {
        out[0] = @intCast(padding_count);
    }
    return @intCast(output_bytes);
}
