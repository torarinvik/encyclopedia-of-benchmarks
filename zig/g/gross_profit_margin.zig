const INVALID_RESULT: f64 = -1.0e300;

export fn gross_profit_margin(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const revenue = values[0];
    const cost = values[1];
    if (revenue < 1 or revenue > 1000000 or cost < 0 or cost > 1000000) return INVALID_RESULT;
    return (@as(f64, @floatFromInt(revenue)) - @as(f64, @floatFromInt(cost))) / @as(f64, @floatFromInt(revenue));
}
