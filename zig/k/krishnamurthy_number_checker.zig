/// Check whether n equals the sum of factorials of its decimal digits.
export fn krishnamurthy_number_checker(n: i64) i64 {
    if (n < -2147483648 or n > 2147483647) return -1;
    if (n <= 0) return 0;

    const original = n;
    var remaining = n;
    var sum: i64 = 0;
    while (remaining != 0) {
        const digit = @rem(remaining, 10);
        var factorial: i64 = 1;
        var factor: i64 = 2;
        while (factor <= digit) : (factor += 1) factorial *= factor;
        sum += factorial;
        remaining = @divTrunc(remaining, 10);
    }
    return if (sum == original) 1 else 0;
}
