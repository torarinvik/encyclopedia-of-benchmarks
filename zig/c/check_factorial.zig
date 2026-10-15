export fn check_factorial(n: i64) i64 {
    if (n <= 0) return 0;
    var value = n;
    var divisor: i64 = 2;
    while (@mod(value, divisor) == 0) {
        value = @divTrunc(value, divisor);
        divisor += 1;
    }
    return if (value == 1) 1 else 0;
}
