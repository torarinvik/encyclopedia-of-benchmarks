module armstrong;

// Check whether n is an Armstrong number in base 10.
fn long armstrong(long n) @export("armstrong") {
    if (n < -2147483648L || n > 2147483647L) return -1L;
    if (n < 0L) return 0L;
    if (n == 0L) return 1L;

    long original = n;
    long remaining = n;
    long digits = 0L;
    while (remaining > 0L) {
        digits++;
        remaining /= 10L;
    }

    long sum = 0L;
    remaining = n;
    while (remaining > 0L) {
        long digit = remaining % 10L;
        long power = 1L;
        for (long exponent = 0L; exponent < digits; exponent++) power *= digit;
        sum += power;
        remaining /= 10L;
    }
    return sum == original ? 1L : 0L;
}
