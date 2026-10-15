fn isPrimeI64(n: i64) bool {
    if (n < 2) return false;
    if (@mod(n, 2) == 0) return n == 2;
    var factor: i64 = 3;
    while (factor <= @divTrunc(n, factor)) : (factor += 2) {
        if (@mod(n, factor) == 0) return false;
    }
    return true;
}

export fn mersenne_prime(n: i64) i64 {
    if (n == 0) return 0;
    if (n < 0 or n > 2147483647) return -1;
    var remaining = n + 1;
    while (@mod(remaining, 2) == 0) {
        remaining = @divTrunc(remaining, 2);
    }
    if (remaining != 1) return 0;
    return if (isPrimeI64(n)) 1 else 0;
}
