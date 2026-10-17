const INVALID_RESULT: i64 = -1;
const MAX_INPUT_LENGTH: usize = 3077;
const MAX_OUTPUT_BYTES: usize = 3072;

export fn resize(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    const src_width = values[0];
    const src_height = values[1];
    const dst_width = values[2];
    const dst_height = values[3];
    if (src_width < 1 or src_width > 32 or src_height < 1 or src_height > 32 or
        dst_width < 1 or dst_width > 32 or dst_height < 1 or dst_height > 32) return INVALID_RESULT;

    const src_w: usize = @intCast(src_width);
    const src_h: usize = @intCast(src_height);
    const dst_w: usize = @intCast(dst_width);
    const dst_h: usize = @intCast(dst_height);
    const expected_length = 4 + 3 * src_w * src_h;
    if (length != expected_length) return INVALID_RESULT;
    for (values[4..expected_length]) |channel| {
        if (channel < 0 or channel > 255) return INVALID_RESULT;
    }

    const needed = 3 * dst_w * dst_h;
    if (needed > MAX_OUTPUT_BYTES) return INVALID_RESULT;
    if (output == null or capacity < needed) return -2;

    const result = output.?[0..needed];
    const ratio_x = @as(f64, @floatFromInt(src_width)) / @as(f64, @floatFromInt(dst_width));
    const ratio_y = @as(f64, @floatFromInt(src_height)) / @as(f64, @floatFromInt(dst_height));
    var out: usize = 0;
    for (0..dst_h) |y| {
        const src_y: usize = @intFromFloat(ratio_y * @as(f64, @floatFromInt(y)));
        for (0..dst_w) |x| {
            const src_x: usize = @intFromFloat(ratio_x * @as(f64, @floatFromInt(x)));
            const src = 4 + 3 * (src_y * src_w + src_x);
            result[out] = @intCast(values[src]);
            result[out + 1] = @intCast(values[src + 1]);
            result[out + 2] = @intCast(values[src + 2]);
            out += 3;
        }
    }
    return @intCast(needed);
}
