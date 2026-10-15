/// Return 1 when n is divisible by its base-10 digit sum, else 0.
export fn harshad_number(n: i64) i64 {
    if (n <= 0 or n > 2147483647) return -1;
    var remaining = n;
    var digit_sum: i64 = 0;
    while (remaining > 0) {
        digit_sum += @rem(remaining, 10);
        remaining = @divTrunc(remaining, 10);
    }
    return if (@rem(n, digit_sum) == 0) 1 else 0;
}
