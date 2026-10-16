const MAX_SAMPLE_COUNT: usize = 128;

fn putF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn data_normalization_standardization(
    values: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (values == null or length < 4 or length > MAX_SAMPLE_COUNT + 2) return -1;
    const input = values.?[0..length];
    const mode = input[0];
    const count_arg = input[1];
    if ((mode != 0 and mode != 1) or count_arg < 2 or count_arg > MAX_SAMPLE_COUNT or
        length != @as(usize, @intCast(count_arg)) + 2) return -1;
    const count: usize = @intCast(count_arg);
    const sample = input[2..];
    var minimum = sample[0];
    var maximum = sample[0];
    var sum: f64 = 0.0;
    for (sample) |value| {
        if (value < -100000 or value > 100000) return -1;
        minimum = @min(minimum, value);
        maximum = @max(maximum, value);
        sum += @floatFromInt(value);
    }
    if (minimum == maximum) return -1;
    const output_bytes = count * 8;
    if (output == null or capacity < output_bytes) return -2;
    const destination = output.?[0..output_bytes];
    if (mode == 0) {
        const span: f64 = @floatFromInt(maximum - minimum);
        for (sample, 0..) |value, index| {
            const normalized = (@as(f64, @floatFromInt(value - minimum))) / span;
            putF64Le(destination.ptr, index * 8, normalized);
        }
    } else {
        const mean = sum / @as(f64, @floatFromInt(count));
        var squared_deviations: f64 = 0.0;
        for (sample) |value| {
            const deviation = @as(f64, @floatFromInt(value)) - mean;
            squared_deviations += deviation * deviation;
        }
        const sample_deviation = @sqrt(squared_deviations / @as(f64, @floatFromInt(count - 1)));
        for (sample, 0..) |value, index| {
            const standardized = (@as(f64, @floatFromInt(value)) - mean) / sample_deviation;
            putF64Le(destination.ptr, index * 8, standardized);
        }
    }
    return @intCast(output_bytes);
}
