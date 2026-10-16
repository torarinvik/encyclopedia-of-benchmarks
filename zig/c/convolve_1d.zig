const MAX_SIGNAL_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_SIGNAL_LENGTH;
const MAX_FIXED_SAMPLE: i64 = 128;
const SAMPLE_SCALE: f64 = 16.0;

fn writeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn convolve_1d(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const raw_signal_count = input[0];
    const raw_kernel_count = input[1];
    if (raw_signal_count < 0 or raw_signal_count > @as(i64, MAX_SIGNAL_LENGTH) or
        raw_kernel_count < 0 or raw_kernel_count > @as(i64, MAX_SIGNAL_LENGTH)) return -1;
    const signal_count: usize = @intCast(raw_signal_count);
    const kernel_count: usize = @intCast(raw_kernel_count);
    if (length != 2 + signal_count + kernel_count) return -1;
    for (0..signal_count + kernel_count) |index| {
        const value = input[index + 2];
        if (value < -MAX_FIXED_SAMPLE or value > MAX_FIXED_SAMPLE) return -1;
    }

    const output_bytes = signal_count * 8;
    if (output_capacity < output_bytes or (output_bytes > 0 and output == null)) return -2;
    const center = kernel_count / 2;
    for (0..signal_count) |i| {
        var accumulated: f64 = 0.0;
        for (0..kernel_count) |j| {
            const signal_index: i64 = @as(i64, @intCast(i)) + @as(i64, @intCast(j))
                - @as(i64, @intCast(center));
            if (signal_index >= 0 and signal_index < @as(i64, @intCast(signal_count))) {
                const kernel_value = @as(f64, @floatFromInt(input[2 + signal_count + j])) / SAMPLE_SCALE;
                const signal_value = @as(f64, @floatFromInt(input[2 + @as(usize, @intCast(signal_index))])) / SAMPLE_SCALE;
                accumulated += kernel_value * signal_value;
            }
        }
        writeF64Le(output, i * 8, accumulated);
    }
    return @intCast(output_bytes);
}
