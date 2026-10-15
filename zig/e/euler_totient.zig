/// Euler's totient via distinct-prime factorization.
export fn euler_totient(n: i64) i64 {
    if (n < 1 or n > 1_000_000) return -1;
    var result = n;
    var remaining = n;
    var factor: i64 = 2;
    while (factor <= @divTrunc(remaining, factor)) : (factor += 1) {
        if (@rem(remaining, factor) == 0) {
            while (@rem(remaining, factor) == 0) {
                remaining = @divTrunc(remaining, factor);
            }
            result -= @divTrunc(result, factor);
        }
    }
    if (remaining > 1) result -= @divTrunc(result, remaining);
    return result;
}
