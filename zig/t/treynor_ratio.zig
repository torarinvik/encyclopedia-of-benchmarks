/// Treynor ratio: (portfolio return - risk-free rate) / beta.
export fn treynor_ratio(values: [*]const i64, length: usize) f64 {
    if (length != 3) return -1.0e300;
    const portfolio_return = values[0];
    const risk_free_rate = values[1];
    const beta = values[2];
    if (portfolio_return < -1000 or portfolio_return > 1000 or
        risk_free_rate < -1000 or risk_free_rate > 1000 or
        beta < -1000 or beta > 1000 or beta == 0) return -1.0e300;
    return @as(f64, @floatFromInt(portfolio_return - risk_free_rate)) / @as(f64, @floatFromInt(beta));
}
