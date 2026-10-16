const MAX_PANELS: i64 = 64;
const MAX_STEP_NANOUNITS: i64 = 1_000_000_000;
const MAX_SAMPLE_MICRO: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn weddles_rule(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 9 or length > 387) return INVALID_RESULT;
    const panels = values[0];
    const step_nanounits = values[1];
    if (panels < 1 or panels > MAX_PANELS or length != @as(usize, @intCast(6 * panels + 3)) or
        step_nanounits < -MAX_STEP_NANOUNITS or step_nanounits > MAX_STEP_NANOUNITS) return INVALID_RESULT;

    const sample_count: usize = @intCast(6 * panels + 1);
    var weighted_sum: f64 = 0.0;
    var index: usize = 1;
    while (index + 1 < sample_count) : (index += 1) {
        const sample_micro = values[index + 2];
        if (sample_micro < -MAX_SAMPLE_MICRO or sample_micro > MAX_SAMPLE_MICRO) return INVALID_RESULT;
        const weight: i64 = if (index % 2 == 0 and index % 3 != 0) 1
            else if (index % 2 != 0 and index % 3 != 0) 5
            else if (index % 6 == 0) 2
            else 6;
        weighted_sum += @as(f64, @floatFromInt(weight)) *
            (@as(f64, @floatFromInt(sample_micro)) / 1_000_000.0);
    }
    const first_micro = values[2];
    const last_micro = values[sample_count + 1];
    if (first_micro < -MAX_SAMPLE_MICRO or first_micro > MAX_SAMPLE_MICRO or
        last_micro < -MAX_SAMPLE_MICRO or last_micro > MAX_SAMPLE_MICRO) return INVALID_RESULT;
    const step_size = @as(f64, @floatFromInt(step_nanounits)) / 1_000_000_000.0;
    return 0.3 * step_size * (weighted_sum + @as(f64, @floatFromInt(first_micro)) / 1_000_000.0 +
                              @as(f64, @floatFromInt(last_micro)) / 1_000_000.0);
}
