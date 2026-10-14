/// Exact decimal digit powers; 1 for Armstrong numbers and 0 otherwise.
export fn armstrong_number(n: i64) i64 {
    if (n < 0) return 0;
    if (n == 0) return 1;
    var digits: i64 = 0;
    var remaining = n;
    while (remaining > 0) : (remaining = @divTrunc(remaining, 10)) digits += 1;
    var sum: i64 = 0;
    remaining = n;
    while (remaining > 0) : (remaining = @divTrunc(remaining, 10)) {
        const digit = @rem(remaining, 10);
        var power: i64 = 1;
        var exponent: i64 = 0;
        while (exponent < digits) : (exponent += 1) power *= digit;
        if (power > n - sum) return 0;
        sum += power;
    }
    return if (sum == n) 1 else 0;
}
