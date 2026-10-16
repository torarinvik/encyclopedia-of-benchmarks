const PI = 3.14159265358979323846264338327950288;

fn putF32Le(output: [*]u8, offset: usize, value: f64) void {
    const rounded: f32 = @floatCast(value);
    const bits: u32 = @bitCast(rounded);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gabor_filter(values: [*c]const i64, length: usize,
                       output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 1 or length > 7) return -1;
    if (length != 6) return -1;
    const requested = values[0];
    const sigma = values[1];
    const theta = values[2];
    const wavelength = values[3];
    const gamma = values[4];
    const phase = values[5];
    if (requested < 1 or requested > 7 or sigma < 1 or sigma > 8) return -1;
    if (theta < 0 or theta > 359 or wavelength < 1 or wavelength > 8) return -1;
    if (gamma < 0 or gamma > 4 or phase < -6 or phase > 6) return -1;

    var side: usize = @intCast(requested);
    if (side % 2 == 0) side += 1;
    const output_bytes = side * side * 4;
    if (output == null or capacity < output_bytes) return -2;

    const angle = (@as(f64, @floatFromInt(theta)) / 180.0) * PI;
    const cosine = @cos(angle);
    const sine = @sin(angle);
    const center = side / 2;
    var offset: usize = 0;
    for (0..side) |y| {
        const py = @as(f64, @floatFromInt(y)) - @as(f64, @floatFromInt(center));
        for (0..side) |x| {
            const px = @as(f64, @floatFromInt(x)) - @as(f64, @floatFromInt(center));
            const kernel_x = cosine * px + sine * py;
            const kernel_y = -sine * px + cosine * py;
            const exponent = -(kernel_x * kernel_x +
                @as(f64, @floatFromInt(gamma * gamma)) * kernel_y * kernel_y) /
                (2.0 * @as(f64, @floatFromInt(sigma)) * @as(f64, @floatFromInt(sigma)));
            const phase_angle = 2.0 * PI * kernel_x / @as(f64, @floatFromInt(wavelength)) +
                @as(f64, @floatFromInt(phase));
            putF32Le(output, offset, @exp(exponent) * @cos(phase_angle));
            offset += 4;
        }
    }
    return @intCast(output_bytes);
}
