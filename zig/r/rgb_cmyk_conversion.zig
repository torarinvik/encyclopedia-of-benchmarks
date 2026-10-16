const OUTPUT_LENGTH: usize = 4;

fn roundTiesToEven(value: f64) i64 {
    const lower = @floor(value);
    const fraction = value - lower;
    const base: i64 = @intFromFloat(lower);
    if (fraction < 0.5) return base;
    if (fraction > 0.5) return base + 1;
    return if (@mod(base, 2) == 0) base else base + 1;
}

export fn rgb_cmyk_conversion(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    for (0..3) |i| if (input[i] < 0 or input[i] > 255) return -1;
    if (output == null or capacity < OUTPUT_LENGTH) return -2;
    const red = @as(f64, @floatFromInt(input[0])) / 255.0;
    const green = @as(f64, @floatFromInt(input[1])) / 255.0;
    const blue = @as(f64, @floatFromInt(input[2])) / 255.0;
    const maximum = @max(@max(red, green), blue);
    const key = 1.0 - maximum;
    if (key == 1.0) { output[0] = 0; output[1] = 0; output[2] = 0; output[3] = 100; return OUTPUT_LENGTH; }
    const denominator = 1.0 - key;
    output[0] = @intCast(roundTiesToEven(100.0 * (1.0 - red - key) / denominator));
    output[1] = @intCast(roundTiesToEven(100.0 * (1.0 - green - key) / denominator));
    output[2] = @intCast(roundTiesToEven(100.0 * (1.0 - blue - key) / denominator));
    output[3] = @intCast(roundTiesToEven(100.0 * key));
    return OUTPUT_LENGTH;
}
