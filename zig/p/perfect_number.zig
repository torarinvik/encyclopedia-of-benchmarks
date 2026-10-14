/// Check whether n equals the sum of its positive proper divisors.
export fn perfect_number(n: i64) i64 {
    if (n <= 1) return 0;
    if (n > 1000000000000) return -1;

    var divisor_sum: i64 = 1;
    var factor: i64 = 2;
    while (factor <= @divTrunc(n, factor)) : (factor += 1) {
        if (@rem(n, factor) == 0) {
            divisor_sum += factor;
            const partner = @divTrunc(n, factor);
            if (partner != factor) divisor_sum += partner;
            if (divisor_sum > n) return 0;
        }
    }
    return if (divisor_sum == n) 1 else 0;
}
