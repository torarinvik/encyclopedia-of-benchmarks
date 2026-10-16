const INVALID_RESULT: f64 = -1.0e300;

export fn debt_to_equity(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const debt = values[0];
    const equity = values[1];
    if (debt < 0 or debt > 1000000 or equity < 1 or equity > 1000000) return INVALID_RESULT;
    return @as(f64, @floatFromInt(debt)) / @as(f64, @floatFromInt(equity));
}
