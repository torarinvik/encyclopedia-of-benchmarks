const MAX_SAMPLE_COUNT: usize = 64;
const MAX_INPUT_LENGTH: usize = 68;
const MIN_SAMPLE_MICRO: i64 = -1_000_000;
const MAX_SAMPLE_MICRO: i64 = 1_000_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn laplace_transformation(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    const sample_count_value = values[0];
    const s_milli = values[1];
    const dt_micro = values[2];
    if (sample_count_value < 1 or sample_count_value > MAX_SAMPLE_COUNT) return INVALID_RESULT;
    const sample_count: usize = @intCast(sample_count_value);
    if (length != sample_count + 3 or s_milli < 0 or s_milli > 1000 or
        dt_micro < 1 or dt_micro > 1_000_000) return INVALID_RESULT;

    var samples = [_]f64{0.0} ** MAX_SAMPLE_COUNT;
    for (0..sample_count) |index| {
        const sample = values[3 + index];
        if (sample < MIN_SAMPLE_MICRO or sample > MAX_SAMPLE_MICRO) return INVALID_RESULT;
        samples[index] = @as(f64, @floatFromInt(sample)) / 1_000_000.0;
    }
    if (sample_count == 1) return 0.0;

    const s_value = @as(f64, @floatFromInt(s_milli)) / 1000.0;
    const delta_t = @as(f64, @floatFromInt(dt_micro)) / 1_000_000.0;
    const stop = @as(f64, @floatFromInt(sample_count - 1)) * delta_t;
    const step = stop / @as(f64, @floatFromInt(sample_count - 1));
    var integrand = [_]f64{0.0} ** MAX_SAMPLE_COUNT;
    for (0..sample_count) |index| {
        const time = if (index == sample_count - 1) stop else @as(f64, @floatFromInt(index)) * step;
        integrand[index] = samples[index] * @exp(-s_value * time);
    }

    var result: f64 = 0.0;
    for (0..sample_count - 1) |index|
        result += (delta_t * (integrand[index] + integrand[index + 1])) / 2.0;
    return result;
}
