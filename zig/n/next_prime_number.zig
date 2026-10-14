/// Find the smallest prime strictly greater than the input.
fn is_prime(value: i64) bool {
    if (value < 2) return false;
    if (value == 2) return true;
    if (@mod(value, 2) == 0) return false;
    var divisor: i64 = 3;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 2) {
        if (@mod(value, divisor) == 0) return false;
    }
    return true;
}

export fn next_prime_number(value: i64) i64 {
    if (value < -4096 or value > 4096) return -1;
    var candidate = value + 1;
    if (candidate < 2) candidate = 2;
    while (!is_prime(candidate)) : (candidate += 1) {}
    return candidate;
}
