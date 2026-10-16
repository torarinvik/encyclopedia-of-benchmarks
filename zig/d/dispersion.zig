fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dispersion(values: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (values == null or length == 0 or length > 128) return -1;
    const input = values.?[0..length];
    for (input) |value| if (value < -10000 or value > 10000) return -1;
    if (output == null or capacity < 16) return -2;
    var sum: f64 = 0.0;
    for (input) |value| sum += @floatFromInt(value);
    const mean = sum / @as(f64, @floatFromInt(length));
    var squared_deviations: f64 = 0.0;
    for (input) |value| {
        const deviation = @as(f64, @floatFromInt(value)) - mean;
        squared_deviations += deviation * deviation;
    }
    const variance = squared_deviations / @as(f64, @floatFromInt(length));
    const result = output.?[0..16];
    putF64Le(result.ptr, 0, variance);
    putF64Le(result.ptr, 8, @sqrt(variance));
    return 16;
}
