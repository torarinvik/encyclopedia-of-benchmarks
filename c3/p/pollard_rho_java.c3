module pollard_rho_java;

const long MIN_N = 2L;
const long MAX_N = 46340L;
const long MAX_STEPS = 4096L;

fn long java_remainder(long value, long modulus) {
    if (value < 0L) return -((-value) % modulus);
    return value % modulus;
}

fn long next_value(long value, long modulus) {
    return java_remainder(value * value - 1L, modulus);
}

fn long gcd_nonnegative(long left, long right) {
    while (right != 0L) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long pollard_rho_java(long* input, usz length) @export("pollard_rho_java") {
    if (input == null || length != 2) return -1L;
    long n = input[0];
    long step_limit = input[1];
    if (n < MIN_N || n > MAX_N || step_limit < 1L || step_limit > MAX_STEPS) return -1L;

    long x = 2L;
    long y = 2L;
    for (long step = 0L; step < step_limit; step += 1L) {
        x = next_value(x, n);
        y = next_value(next_value(y, n), n);
        long difference = x - y;
        if (difference < 0L) difference = -difference;
        long divisor = gcd_nonnegative(difference, n);
        if (divisor == 1L) continue;
        if (divisor == n) return 0L;
        return divisor;
    }
    return -2L;
}
