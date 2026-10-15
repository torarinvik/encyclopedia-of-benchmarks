/// Check whether n equals the sum of each decimal digit raised to digit count.
export fn narcissistic_number_checker(n: i64) i64 {
    if (n < -2147483648 or n > 999999) return -1;

    const original = n;
    var remaining = n;
    var digits: i64 = 0;
    while (remaining != 0) : (digits += 1) {
        remaining = @divTrunc(remaining, 10);
    }

    var sum: i64 = 0;
    remaining = n;
    while (remaining > 0) {
        const digit = @rem(remaining, 10);
        var power: i64 = 1;
        var exponent: i64 = 0;
        while (exponent < digits) : (exponent += 1) power *= digit;
        sum += power;
        remaining = @divTrunc(remaining, 10);
    }
    return if (sum == original) 1 else 0;
}
