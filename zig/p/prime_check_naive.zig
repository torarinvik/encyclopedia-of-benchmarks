/// Unoptimized trial division under a bounded positive input contract.
export fn prime_check_naive(n: i64) i64 {
    if (n > 10000) return -1;
    if (n < 2) return 0;
    var divisor: i64 = 2;
    while (divisor < n) : (divisor += 1) {
        if (@rem(n, divisor) == 0) return 0;
    }
    return 1;
}
