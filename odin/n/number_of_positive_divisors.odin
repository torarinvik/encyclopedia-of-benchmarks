package number_of_positive_divisors

// Count positive divisors of the absolute value of one signed integer.
@(export)
number_of_positive_divisors :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 1 || values[0] < -1000000000 || values[0] > 1000000000 do return -1
    remaining := values[0]
    if remaining < 0 do remaining = -remaining
    count := i64(1)
    for factor := i64(2); factor * factor <= remaining; factor += 1 {
        exponent := i64(0)
        for remaining % factor == 0 {
            remaining /= factor
            exponent += 1
        }
        count *= exponent + 1
    }
    if remaining > 1 do count *= 2
    return count
}
