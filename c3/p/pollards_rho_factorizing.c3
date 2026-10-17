module pollards_rho_factorizing;

const long MIN_N = 2L;
const long MAX_N = 46340L;

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

long pollards_rho_factorizing(long n) @export("pollards_rho_factorizing") {
    if (n < MIN_N || n > MAX_N) return -1L;
    long x = 2L, y = 2L, divisor = 1L;
    while (divisor == 1L) {
        x = next_value(n, x);
        y = next_value(n, next_value(n, y));
        long difference = x - y;
        if (difference < 0L) difference = -difference;
        divisor = gcd_nonnegative(difference, n);
    }
    return divisor;
}
