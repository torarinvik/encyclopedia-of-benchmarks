fn writeF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| output[offset + i] = @truncate(bits >> @intCast(8 * i));
}

export fn rgb_hsv_conversion(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    for (0..3) |i| if (input[i] < 0 or input[i] > 255) return -1;
    if (output == null or capacity < 24) return -2;
    const red = @as(f64, @floatFromInt(input[0])) / 255.0;
    const green = @as(f64, @floatFromInt(input[1])) / 255.0;
    const blue = @as(f64, @floatFromInt(input[2])) / 255.0;
    const value = @max(@max(red, green), blue);
    const chroma = value - @min(@min(red, green), blue);
    const saturation: f64 = if (value == 0.0) 0.0 else chroma / value;
    var hue: f64 = 0.0;
    if (chroma != 0.0) {
        if (value == red) hue = 60.0 * (0.0 + (green - blue) / chroma)
        else if (value == green) hue = 60.0 * (2.0 + (blue - red) / chroma)
        else hue = 60.0 * (4.0 + (red - green) / chroma);
    }
    hue += 360.0;
    if (hue >= 360.0) hue -= 360.0;
    writeF64Le(output, 0, hue);
    writeF64Le(output, 8, saturation);
    writeF64Le(output, 16, value);
    return 24;
}
