/// Return n + 2 when n and n + 2 are twin primes, otherwise -1.
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

export fn twin_prime(value: i64) i64 {
    if (value < -4096 or value > 4096) return -1;
    if (is_prime(value) and is_prime(value + 2)) return value + 2;
    return -1;
}
