/// Match n against the signed sum of the cubes of its decimal digits.
export fn armstrong_digit_cubes(n: i64) i64 {
    if (n < -2147483648 or n > 2147483647) return -1;
    const original = n;
    var magnitude = if (n < 0) -n else n;
    var sum: i64 = 0;
    while (magnitude > 0) {
        const digit = @rem(magnitude, 10);
        sum += digit * digit * digit;
        magnitude = @divTrunc(magnitude, 10);
    }
    if (original < 0) sum = -sum;
    return if (sum == original) 1 else 0;
}
