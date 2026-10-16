const SCALE: i64 = 1_000_000;
const MAX_SIGNAL_MICRO: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn comp_filt(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length < 6 or length > 68) return INVALID_RESULT;
    const input = values.?;
    const alpha_ppm = input[0];
    const delta_t_micro = input[1];
    const count_value = input[2];
    const output_index_value = input[3];
    if (alpha_ppm < 0 or alpha_ppm > SCALE or delta_t_micro < 0 or delta_t_micro > SCALE or
        count_value < 1 or count_value > 32 or output_index_value < 0 or output_index_value > count_value)
        return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    const output_index: usize = @intCast(output_index_value);
    if (length != 4 + 2 * count) return INVALID_RESULT;
    for (0..count) |i| {
        const rate = input[4 + i];
        const reference = input[4 + count + i];
        if (rate < -MAX_SIGNAL_MICRO or rate > MAX_SIGNAL_MICRO or
            reference < -MAX_SIGNAL_MICRO or reference > MAX_SIGNAL_MICRO) return INVALID_RESULT;
    }
    const alpha = @as(f64, @floatFromInt(alpha_ppm)) / @as(f64, @floatFromInt(SCALE));
    const delta_t = @as(f64, @floatFromInt(delta_t_micro)) / @as(f64, @floatFromInt(SCALE));
    var theta = @as(f64, @floatFromInt(input[4 + count])) / @as(f64, @floatFromInt(SCALE));
    for (0..output_index) |i| {
        const rate = @as(f64, @floatFromInt(input[4 + i])) / @as(f64, @floatFromInt(SCALE));
        const reference = @as(f64, @floatFromInt(input[4 + count + i])) / @as(f64, @floatFromInt(SCALE));
        theta = alpha * (theta + rate * delta_t) + (1.0 - alpha) * reference;
    }
    return theta;
}
