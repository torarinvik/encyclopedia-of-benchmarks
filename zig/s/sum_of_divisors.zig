/// Return the sum of all positive divisors of n by prime factorization.
export fn sum_of_divisors(n: i64) i64 {
    if (n < 1 or n > 1_000_000) return -1;
    var remaining = n;
    var sigma: i64 = 1;
    var factor: i64 = 2;
    while (factor <= @divTrunc(remaining, factor)) : (factor += 1) {
        if (@rem(remaining, factor) == 0) {
            var power: i64 = 1;
            var geometric_sum: i64 = 1;
            while (@rem(remaining, factor) == 0) {
                remaining = @divTrunc(remaining, factor);
                power *= factor;
                geometric_sum += power;
            }
            sigma *= geometric_sum;
        }
    }
    if (remaining > 1) sigma *= remaining + 1;
    return sigma;
}
