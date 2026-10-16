export fn abundant_number(n: i64) i64 {
    if (n < 1 or n > 100_000_000) return -1;
    if (n == 1) return 0;
    var sum: i64 = 1;
    var divisor: i64 = 2;
    while (divisor <= @divTrunc(n, divisor)) : (divisor += 1) {
        if (@rem(n, divisor) == 0) {
            sum += divisor;
            const partner = @divTrunc(n, divisor);
            if (partner != divisor) sum += partner;
            if (sum > n) return 1;
        }
    }
    return 0;
}
