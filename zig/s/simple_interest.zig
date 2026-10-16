export fn simple_interest(principal: f64, daily_rate: f64, days: f64) f64 {
    if (principal != principal or daily_rate != daily_rate or days != days or
        !(principal > 0.0) or principal > 1_000_000.0 or
        !(daily_rate >= 0.0) or daily_rate > 1.0 or
        !(days > 0.0) or days > 3_650.0) return -1e300;
    return principal * daily_rate * days;
}
