fn factorialDivisorCompositeKValuation(n: u64, prime: u64) u64 {
    var quotient = n;
    var total: u64 = 0;
    while (quotient != 0) {
        quotient /= prime;
        total += quotient;
    }
    return total;
}

export fn factorial_divisor_composite_k(n: u64, k: u64) i64 {
    if (n > 1_000_000_000_000 or k < 4 or k > 1_000_000) return -1;

    var remaining = k;
    var divisor: u64 = 2;
    var answer = n;
    var composite = false;
    while (divisor <= remaining / divisor) : (divisor += 1) {
        if (remaining % divisor == 0) {
            composite = true;
            var exponent: u64 = 0;
            while (remaining % divisor == 0) {
                remaining /= divisor;
                exponent += 1;
            }
            const candidate = factorialDivisorCompositeKValuation(n, divisor) / exponent;
            if (candidate < answer) answer = candidate;
        }
    }

    if (!composite) return -1;
    if (remaining > 1) {
        const candidate = factorialDivisorCompositeKValuation(n, remaining);
        if (candidate < answer) answer = candidate;
    }
    return @intCast(answer);
}
