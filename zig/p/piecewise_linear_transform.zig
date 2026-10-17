export fn piecewise_linear_transform(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > 256) return -1;
    for (0..length) |index| if (input[index] < 0 or input[index] > 255) return -1;
    if (output == null or capacity < length) return -2;
    for (0..length) |index| {
        const pixel: f64 = @floatFromInt(input[index]);
        const mapped = if (pixel <= 100.0)
            (50.0 / 100.0) * pixel
        else if (pixel <= 180.0)
            ((200.0 - 50.0) / (180.0 - 100.0)) * (pixel - 100.0) + 50.0
        else
            ((255.0 - 200.0) / (255.0 - 180.0)) * (pixel - 180.0) + 200.0;
        output[index] = @intFromFloat(mapped);
    }
    return @intCast(length);
}
