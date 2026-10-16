module simple_interest;

fn double simple_interest(double principal, double daily_rate, double days) @export("simple_interest") {
    if (principal != principal || daily_rate != daily_rate || days != days ||
        !(principal > 0.0) || principal > 1000000.0 ||
        !(daily_rate >= 0.0) || daily_rate > 1.0 ||
        !(days > 0.0) || days > 3650.0) return -1e300;
    return principal * daily_rate * days;
}
