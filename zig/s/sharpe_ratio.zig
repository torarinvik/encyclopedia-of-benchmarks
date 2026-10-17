const MAX_PARSEABLE_LENGTH: usize = 67;
const MAX_SAMPLE_COUNT: i64 = 64;
const SCALE: f64 = 1_000_000.0;
const MIN_RETURN_MICRO: i64 = -200_000;
const MAX_RETURN_MICRO: i64 = 200_000;
const MIN_RISK_FREE_MICRO: i64 = -100_000;
const MAX_RISK_FREE_MICRO: i64 = 100_000;
const INVALID_RESULT: f64 = -1.0e300;

export fn sharpe_ratio(values_opt: ?[*]const i64, length: usize) f64 {
    if (values_opt == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return INVALID_RESULT;
    const values = values_opt.?[0..length];
    const count_value = values[0];
    if (count_value < 2 or count_value > MAX_SAMPLE_COUNT
        or length != @as(usize, @intCast(count_value)) + 2) return INVALID_RESULT;
    const count: usize = @intCast(count_value);
    const risk_free_micro = values[count + 1];
    if (risk_free_micro < MIN_RISK_FREE_MICRO or risk_free_micro > MAX_RISK_FREE_MICRO)
        return INVALID_RESULT;

    var sum: f64 = 0.0;
    var constant_returns = true;
    for (0..count) |index| {
        const return_micro = values[index + 1];
        if (return_micro < MIN_RETURN_MICRO or return_micro > MAX_RETURN_MICRO)
            return INVALID_RESULT;
        if (return_micro != values[1]) constant_returns = false;
        sum += @as(f64, @floatFromInt(return_micro)) / SCALE;
    }
    if (constant_returns) return INVALID_RESULT;

    const mean = sum / @as(f64, @floatFromInt(count));
    const risk_free_rate = @as(f64, @floatFromInt(risk_free_micro)) / SCALE;
    const excess_return = mean - risk_free_rate;
    var squared_deviations: f64 = 0.0;
    for (0..count) |index| {
        const return_value = @as(f64, @floatFromInt(values[index + 1])) / SCALE;
        const difference = return_value - mean;
        squared_deviations += @pow(difference, 2.0);
    }
    const variance = squared_deviations / @as(f64, @floatFromInt(count - 1));
    const standard_deviation = @sqrt(variance);
    if (standard_deviation == 0.0) return INVALID_RESULT;
    return excess_return / standard_deviation;
}
