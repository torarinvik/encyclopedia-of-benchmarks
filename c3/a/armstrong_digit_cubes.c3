module armstrong_digit_cubes;

// Match n against the signed sum of the cubes of its decimal digits.
fn long armstrong_digit_cubes(long n) @export("armstrong_digit_cubes") {
    if (n < -2147483648L || n > 2147483647L) return -1L;
    long original = n;
    long magnitude = n < 0L ? -n : n;
    long sum = 0L;
    while (magnitude > 0L) {
        long digit = magnitude % 10L;
        sum += digit * digit * digit;
        magnitude /= 10L;
    }
    if (original < 0L) sum = -sum;
    return sum == original ? 1L : 0L;
}
