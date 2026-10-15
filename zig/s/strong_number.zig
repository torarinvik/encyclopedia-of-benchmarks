/// Check whether the sum of the decimal digits' factorials equals the input.
export fn strong_number(number: i64) i64 {
    if (number < -2147483648 or number > 2147483647) return -1;
    if (number < 0) return 0;
    var remaining = number;
    var sum: i64 = 0;
    if (remaining == 0) sum = 1;
    while (remaining > 0) {
        const digit = @mod(remaining, 10);
        var factorial: i64 = 1;
        var factor: i64 = 2;
        while (factor <= digit) : (factor += 1) factorial *= factor;
        sum += factorial;
        remaining = @divTrunc(remaining, 10);
    }
    return if (sum == number) 1 else 0;
}
