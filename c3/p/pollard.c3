module pollard;

const long MIN_N = 2L;
const long MAX_N = 111155L;

fn long next_value(long n, long x) {
    return (x * x + 1L) % n;
}

fn long gcd_nonnegative(long left, long right) {
    while (right != 0L) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long pollard(long* input, usz length) @export("pollard") {
    if (input == null || length != 1) return -1L;
    long n = input[0];
    if (n < MIN_N || n > MAX_N) return -1L;

    long x = 2L;
    long y = 2L;
    long divisor = 1L;
    while (divisor == 1L) {
        x = next_value(n, x);
        y = next_value(n, next_value(n, y));
        long difference = x - y;
        if (difference < 0L) difference = -difference;
        divisor = gcd_nonnegative(difference, n);
    }
    if (divisor == n) return 0L;
    return divisor;
}
