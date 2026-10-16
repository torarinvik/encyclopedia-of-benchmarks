module simple_interest

@[export: 'simple_interest']
pub fn simple_interest(principal f64, daily_rate f64, days f64) f64 {
    if principal != principal || daily_rate != daily_rate || days != days ||
        !(principal > 0.0) || principal > 1_000_000.0 ||
        !(daily_rate >= 0.0) || daily_rate > 1.0 ||
        !(days > 0.0) || days > 3_650.0 { return -1e300 }
    return principal * daily_rate * days
}
