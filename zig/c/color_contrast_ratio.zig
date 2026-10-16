const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

fn component(channel: i64) f64 {
    const srgb = @as(f64, @floatFromInt(channel)) / 255.0;
    if (srgb <= 0.03928) return srgb / 12.92;
    return std.math.pow(f64, (srgb + 0.055) / 1.055, 2.4);
}

fn luminance(red: i64, green: i64, blue: i64) f64 {
    return 0.2126 * component(red) + 0.7152 * component(green) + 0.0722 * component(blue);
}

export fn color_contrast_ratio(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length != 6) return INVALID_RESULT;
    const input = values.?;
    for (0..6) |i| {
        if (input[i] < 0 or input[i] > 255) return INVALID_RESULT;
    }
    const first = luminance(input[0], input[1], input[2]);
    const second = luminance(input[3], input[4], input[5]);
    if (first > second) return (first + 0.05) / (second + 0.05);
    return (second + 0.05) / (first + 0.05);
}
