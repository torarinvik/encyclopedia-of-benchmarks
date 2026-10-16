/// Portable byte-channel brightness and contrast transforms.
fn truncateDivide(numerator: i64, denominator: i64) i64 {
    return if (numerator < 0) -@divTrunc(-numerator, denominator)
        else @divTrunc(numerator, denominator);
}
fn transformChannel(channel: i64, level: i64, mode: i64) i64 {
    var value = channel + level;
    if (mode != 0) {
        const denominator = 255 * (259 - level);
        const numerator = 128 * denominator + 259 * (level + 255) * (channel - 128);
        value = truncateDivide(numerator, denominator);
    }
    return @min(255, @max(0, value));
}
fn imagePointTransform(values: [*c]const i64, length: usize, output: [*c]u8,
                        output_capacity: usize, mode: i64) i64 {
    if (values == null or length < 1 or length > 4096) return -1;
    const level = values[0];
    if (level < -255 or level > 255) return -1;
    const channels = length - 1;
    for (0..channels) |index| {
        if (values[index + 1] < 0 or values[index + 1] > 255) return -1;
    }
    if (channels > output_capacity or (channels != 0 and output == null)) return -2;
    if (channels == 0) return 0;
    const out = output[0..channels];
    for (0..channels) |index| {
        out[index] = @intCast(transformChannel(values[index + 1], level, mode));
    }
    return @intCast(channels);
}
export fn change_brightness(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    return imagePointTransform(values, length, output, output_capacity, 0);
}
export fn change_contrast(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    return imagePointTransform(values, length, output, output_capacity, 1);
}
