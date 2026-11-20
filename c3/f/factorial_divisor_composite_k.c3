module factorial_divisor_composite_k;

fn ulong factorial_divisor_composite_k_valuation(ulong n, ulong prime)
{
    ulong total = 0;
    while n != 0 {
        n /= prime;
        total += n;
    }
    return total;
}

fn long factorial_divisor_composite_k(ulong n, ulong k) @export("factorial_divisor_composite_k")
{
    if (n > 1000000000000 || k < 4 || k > 1000000) return -1;

    ulong remaining = k;
    ulong divisor = 2;
    ulong answer = n;
    bool composite = false;
    while divisor <= remaining / divisor {
        if (remaining % divisor == 0) {
            composite = true;
            ulong exponent = 0;
            while remaining % divisor == 0 {
                remaining /= divisor;
                exponent += 1;
            }
            ulong candidate = factorial_divisor_composite_k_valuation(n, divisor) / exponent;
            if (candidate < answer) answer = candidate;
        }
        divisor += 1;
    }

    if (!composite) return -1;
    if (remaining > 1) {
        ulong candidate = factorial_divisor_composite_k_valuation(n, remaining);
        if (candidate < answer) answer = candidate;
    }
    return (long)answer;
}
