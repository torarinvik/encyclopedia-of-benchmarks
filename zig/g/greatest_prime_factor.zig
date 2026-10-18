/// Greatest prime factor over the bounded primelib input domain.
fn is_prime_trial(value: i64) bool {
    if (value < 2) return false;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(value, divisor)) : (divisor += 1) {
        if (@rem(value, divisor) == 0) return false;
    }
    return true;
}

export fn greatest_prime_factor(n: i64) i64 {
    if (n < 0 or n > 1_000_000) return -1;
    if (n < 2) return n;
    if (is_prime_trial(n)) return n;

    var quotient = n;
    var largest: i64 = 0;
    var factor: i64 = 2;
    while (quotient != 1) {
        if (is_prime_trial(factor) and @rem(quotient, factor) == 0) {
            largest = factor;
            quotient = @divTrunc(quotient, factor);
        } else {
            factor += 1;
        }
    }
    return largest;
}
