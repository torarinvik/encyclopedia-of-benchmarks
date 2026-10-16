/// Apply the bounded Java EMAFilter recurrence to an integer sample stream.
fn put_f64_le(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn ema_filter(input: [*c]const i64, length: usize,
                     output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 7) return -1;
    const alpha_units = input[0];
    const count_value = input[1];
    if (alpha_units < 1 or alpha_units > 1024 or count_value < 0 or count_value > 4 or
        length != 2 + @as(usize, @intCast(count_value))) return -1;
    const count: usize = @intCast(count_value);
    for (0..count) |index| {
        if (input[index + 2] < -1_000_000 or input[index + 2] > 1_000_000) return -1;
    }
    const required = count * 8;
    if (output_capacity < required or (required > 0 and output == null)) return -2;

    const alpha: f64 = @as(f64, @floatFromInt(alpha_units)) / 1024.0;
    var ema_value: f64 = 0.0;
    for (0..count) |index| {
        const sample: f64 = @floatFromInt(input[index + 2]);
        if (index == 0) {
            ema_value = sample;
        } else {
            ema_value = alpha * sample + (1.0 - alpha) * ema_value;
        }
        put_f64_le(output, index * 8, ema_value);
    }
    return @intCast(required);
}
