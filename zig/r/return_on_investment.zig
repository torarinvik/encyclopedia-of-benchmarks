const INVALID_RESULT: f64 = -1.0e300;

export fn return_on_investment(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const gain = values[0];
    const cost = values[1];
    if (gain < -1000000 or gain > 1000000 or cost < 1 or cost > 1000000) return INVALID_RESULT;
    return (@as(f64, @floatFromInt(gain)) - @as(f64, @floatFromInt(cost))) / @as(f64, @floatFromInt(cost));
}
