const INVALID_RESULT: f64 = -1.0e300;
const SCALE: i64 = 1_000_000;
const MAX_SIGNAL_MICRO: i64 = 1_000_000;

export fn complementary_filter(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length < 2) return INVALID_RESULT;
    const input = values.?;
    const coefficient_ppm = input[0];
    const sample_count_value = input[1];
    if (coefficient_ppm < 1 or coefficient_ppm >= SCALE or sample_count_value < 1 or sample_count_value > 32)
        return INVALID_RESULT;
    const sample_count: usize = @intCast(sample_count_value);
    if (length != 2 + 3 * sample_count) return INVALID_RESULT;
    for (0..sample_count) |sample| {
        const rate = input[2 + 3 * sample];
        const reference = input[3 + 3 * sample];
        const elapsed = input[4 + 3 * sample];
        if (rate < -MAX_SIGNAL_MICRO or rate > MAX_SIGNAL_MICRO or reference < -MAX_SIGNAL_MICRO or
            reference > MAX_SIGNAL_MICRO or elapsed < 1 or elapsed > SCALE) return INVALID_RESULT;
    }
    const coefficient = @as(f64, @floatFromInt(coefficient_ppm)) / @as(f64, @floatFromInt(SCALE));
    var value: f64 = 0.0;
    for (0..sample_count) |sample| {
        const rate = @as(f64, @floatFromInt(input[2 + 3 * sample])) / @as(f64, @floatFromInt(SCALE));
        const reference = @as(f64, @floatFromInt(input[3 + 3 * sample])) / @as(f64, @floatFromInt(SCALE));
        const elapsed = @as(f64, @floatFromInt(input[4 + 3 * sample])) / @as(f64, @floatFromInt(SCALE));
        if (sample == 0) value = reference else value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference;
    }
    return value;
}
