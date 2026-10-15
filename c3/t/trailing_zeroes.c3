module trailing_zeroes;

// Count decimal zero digits at the end of a nonnegative integer.
fn long trailing_zeroes(long n) @export("trailing_zeroes") {
    if (n < 0) return -1;
    if (n == 0) return 1;
    long count = 0;
    while (n % 10 == 0) {
        count++;
        n /= 10;
    }
    return count;
}
