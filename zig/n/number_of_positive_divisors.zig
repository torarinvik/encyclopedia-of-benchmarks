/// Count positive divisors of the absolute value of one signed integer.
export fn number_of_positive_divisors(values: [*]const i64, length: usize) i64 {
    if (length != 1 or values[0] < -1_000_000_000 or values[0] > 1_000_000_000) return -1;
    var remaining = values[0];
    if (remaining < 0) remaining = -remaining;
    var count: i64 = 1;
    var factor: i64 = 2;
    while (factor * factor <= remaining) : (factor += 1) {
        var exponent: i64 = 0;
        while (@mod(remaining, factor) == 0) {
            remaining = @divTrunc(remaining, factor);
            exponent += 1;
        }
        count *= exponent + 1;
    }
    if (remaining > 1) count *= 2;
    return count;
}
