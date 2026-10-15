module number_of_positive_divisors;

// Count positive divisors of the absolute value of one signed integer.
fn long number_of_positive_divisors(long* values, usz length) @export("number_of_positive_divisors") {
    if (values == null || length != 1 || values[0] < -1000000000 || values[0] > 1000000000)
        return -1;
    long remaining = values[0] < 0 ? -values[0] : values[0];
    long count = 1;
    for (long factor = 2; factor * factor <= remaining; factor++) {
        long exponent = 0;
        while (remaining % factor == 0) {
            remaining /= factor;
            exponent++;
        }
        count *= exponent + 1;
    }
    if (remaining > 1) count *= 2;
    return count;
}
