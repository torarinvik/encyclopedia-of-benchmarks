const MAX_PARSEABLE_INPUT_LENGTH: usize = 292;

export fn lsb_image_steganography(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    if (values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 16 or values[2] < 0 or values[2] > 32) return -1;
    const rows: usize = @intCast(values[0]);
    const columns: usize = @intCast(values[1]);
    const message_length: usize = @intCast(values[2]);
    const pixel_count = rows * columns;
    if (message_length * 8 > pixel_count or length != 3 + pixel_count + message_length) return -1;
    for (values[3 .. 3 + pixel_count]) |pixel| if (pixel < 0 or pixel > 254) return -1;
    for (values[3 + pixel_count ..]) |byte| if (byte < 0 or byte > 127) return -1;
    if (output == null or output_capacity < pixel_count) return -2;
    const result = output.?[0..pixel_count];
    for (0..pixel_count) |i| result[i] = @intCast(values[3 + i]);
    var bit_index: usize = 0;
    for (0..message_length) |i| {
        const byte: u8 = @intCast(values[3 + pixel_count + i]);
        var shift: i32 = 7;
        while (shift >= 0) : (shift -= 1) {
            const bit = (byte >> @intCast(shift)) & 1;
            const pixel = result[bit_index];
            result[bit_index] = pixel + ((pixel & 1) ^ bit);
            bit_index += 1;
        }
    }
    return @intCast(pixel_count);
}
