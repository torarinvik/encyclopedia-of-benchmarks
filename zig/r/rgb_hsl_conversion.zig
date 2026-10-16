const OUTPUT_COUNT: usize = 4;

export fn rgb_hsl_conversion(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    for (0..3) |i| if (input[i] < 0 or input[i] > 255) return -1;
    if (output == null or capacity < OUTPUT_COUNT) return -2;

    const red = @as(f64, @floatFromInt(input[0])) / 255.0;
    const green = @as(f64, @floatFromInt(input[1])) / 255.0;
    const blue = @as(f64, @floatFromInt(input[2])) / 255.0;
    const minimum = @min(red, @min(green, blue));
    const maximum = @max(red, @max(green, blue));
    var channel: u8 = 0;
    if (maximum == green) channel = 1 else if (maximum == blue) channel = 2;
    const luminance = (minimum + maximum) / 2.0;
    var saturation: f64 = 0.0;
    if (minimum != maximum) {
        if (luminance <= 0.5) saturation = (maximum - minimum) / (maximum + minimum)
        else saturation = (maximum - minimum) / (2.0 - maximum - minimum);
    }
    var hue: f64 = 0.0;
    if (saturation != 0.0) {
        if (channel == 0) hue = (green - blue) / (maximum - minimum)
        else if (channel == 1) hue = 2.0 + (blue - red) / (maximum - minimum)
        else hue = 4.0 + (red - green) / (maximum - minimum);
    }
    hue *= 60.0;
    if (hue < 0.0) hue += 360.0;
    const h: u16 = @intFromFloat(hue + 0.5);
    output[0] = @truncate(h);
    output[1] = @truncate(h >> 8);
    output[2] = @intFromFloat(saturation * 100.0 + 0.5);
    output[3] = @intFromFloat(luminance * 100.0 + 0.5);
    return OUTPUT_COUNT;
}
