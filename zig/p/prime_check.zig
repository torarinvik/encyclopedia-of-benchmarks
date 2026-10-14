/// Trial-division primality check over the shared bounded integer domain.
export fn prime_check(n: i64) i64 {
    if (n < 2) return 0;
    if (n > 2147483647) return -1;
    if (@rem(n, 2) == 0) return if (n == 2) 1 else 0;
    var factor: i64 = 3;
    while (factor <= @divTrunc(n, factor)) : (factor += 2) {
        if (@rem(n, factor) == 0) return 0;
    }
    return 1;
}
