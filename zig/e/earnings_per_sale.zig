const INVALID_RESULT: f64 = -1.0e300;

export fn earnings_per_sale(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 3) return INVALID_RESULT;
    const net_income = values[0];
    const preferred_dividend = values[1];
    const average_shares = values[2];
    if (net_income < -1000000 or net_income > 1000000 or preferred_dividend < 0 or preferred_dividend > 1000000 or average_shares < 1 or average_shares > 1000000) return INVALID_RESULT;
    return (@as(f64, @floatFromInt(net_income)) - @as(f64, @floatFromInt(preferred_dividend))) / @as(f64, @floatFromInt(average_shares));
}
