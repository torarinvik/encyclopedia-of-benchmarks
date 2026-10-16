const rgb_channel_count: usize = 3;
const rgb_hex_output_length: usize = 7;

fn hexDigit(value: i64) u8 {
    if (value < 10) return @intCast(48 + value);
    return @intCast(87 + value);
}

export fn rgbto_hex(input: [*c]const i64, length: usize,
                    output: [*c]u8, capacity: usize) i64 {
    if (length != rgb_channel_count or input == null) return -1;
    for (0..rgb_channel_count) |i| {
        if (input[i] < 0 or input[i] > 255) return -1;
    }
    if (capacity < rgb_hex_output_length or output == null) return -2;
    output[0] = '#';
    for (0..rgb_channel_count) |i| {
        output[1 + 2 * i] = hexDigit(input[i] >> 4);
        output[2 + 2 * i] = hexDigit(input[i] & 15);
    }
    return @intCast(rgb_hex_output_length);
}
