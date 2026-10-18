const MAX_PARSEABLE_INPUT_LENGTH: usize = 196;
const MAX_OUTPUT_BYTES: usize = 192;

export fn sepia(input: [*c]const i64, input_length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or input_length < 3 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const height = input[0];
    const width = input[1];
    const factor = input[2];
    if (height < 1 or height > 8 or width < 1 or width > 8 or factor < 0 or factor > 255) return -1;
    const pixels: usize = @intCast(height * width);
    if (input_length != 3 + 3 * pixels) return -1;
    for (0..3 * pixels) |index| {
        const channel = input[3 + index];
        if (channel != 0 and channel != 64 and channel != 128 and channel != 255) return -1;
    }

    var staged: [MAX_OUTPUT_BYTES]u8 = undefined;
    for (0..pixels) |pixel| {
        const offset = 3 + 3 * pixel;
        const blue: f64 = @floatFromInt(input[offset]);
        const green: f64 = @floatFromInt(input[offset + 1]);
        const red: f64 = @floatFromInt(input[offset + 2]);
        const gray: i64 = @intFromFloat(0.2126 * red + 0.587 * green + 0.114 * blue);
        staged[3 * pixel] = @intCast(gray);
        staged[3 * pixel + 1] = @intCast(@min(gray + factor, 255));
        staged[3 * pixel + 2] = @intCast(@min(gray + 2 * factor, 255));
    }

    const output_bytes = 3 * pixels;
    if (output == null or capacity < output_bytes) return -2;
    @memcpy(output[0..output_bytes], staged[0..output_bytes]);
    return @intCast(output_bytes);
}
