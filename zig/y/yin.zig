const INVALID_RESULT: f64 = -1.0e300;
const MAX_SAMPLES: usize = 256;

export fn yin(input: [*c]const i64, length: usize) f64 {
    if (input == null or length < 7 or length > MAX_SAMPLES + 5) return INVALID_RESULT;
    const values = input;
    const count_v = values[0];
    const rate_v = values[1];
    const min_v = values[2];
    const max_v = values[3];
    const threshold_v = values[4];
    if (count_v < 2 or count_v > MAX_SAMPLES or length != 5 + @as(usize, @intCast(count_v)) or
        rate_v < 1 or rate_v > 192000 or min_v < 1 or max_v <= min_v or max_v > @divTrunc(rate_v, 2) or
        threshold_v < 1 or threshold_v > 999999) return INVALID_RESULT;
    const count: usize = @intCast(count_v);
    for (0..count) |i| if (values[5 + i] < -32768 or values[5 + i] > 32767) return INVALID_RESULT;
    const min_lag_v = @divTrunc(rate_v, max_v);
    const max_lag_v = @divTrunc(rate_v, min_v);
    const max_allowed = @min(@as(i64, 64), @as(i64, @intCast(count - 1)));
    if (min_lag_v < 1 or min_lag_v > max_lag_v or max_lag_v > max_allowed) return INVALID_RESULT;
    const min_lag: usize = @intCast(min_lag_v);
    const max_lag: usize = @intCast(max_lag_v);
    var difference: [65]f64 = @splat(0.0);
    var cmndf: [65]f64 = @splat(1.0);
    var running: f64 = 0.0;
    for (1..max_lag + 1) |lag| {
        var sum: f64 = 0.0;
        for (0..count - lag) |i| {
            const delta = @as(f64, @floatFromInt(values[5 + i])) - @as(f64, @floatFromInt(values[5 + i + lag]));
            sum += delta * delta;
        }
        difference[lag] = sum;
        running += sum;
        cmndf[lag] = sum * @as(f64, @floatFromInt(lag)) / (if (running == 0.0) 1.0e-10 else running);
    }
    var lag = min_lag;
    while (lag <= max_lag and !(cmndf[lag] < @as(f64, @floatFromInt(threshold_v)) / 1000000.0)) : (lag += 1) {}
    if (lag > max_lag) return INVALID_RESULT;
    while (lag < max_lag and cmndf[lag + 1] < cmndf[lag]) : (lag += 1) {}
    const left = if (lag > 1) lag - 1 else lag;
    const right = @min(max_lag, lag + 1);
    const denominator = cmndf[left] - 2.0 * cmndf[lag] + cmndf[right];
    const offset = if (denominator == 0.0) 0.0 else (cmndf[left] - cmndf[right]) / (2.0 * denominator);
    const refined = @as(f64, @floatFromInt(lag)) + offset;
    if (!(refined > 0.0)) return INVALID_RESULT;
    return @as(f64, @floatFromInt(rate_v)) / refined;
}
