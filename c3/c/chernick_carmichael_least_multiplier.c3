module chernick_carmichael_least_multiplier;

const long MAX_MULTIPLIER = 950560;

fn bool is_prime(long value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (long divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn bool has_prime_factors(long n, long multiplier) {
    if (!is_prime(6 * multiplier + 1) || !is_prime(12 * multiplier + 1)) return false;
    long base = 9 * multiplier;
    for (long exponent = 1; exponent <= n - 2; ++exponent) {
        if (!is_prime(base * (1L << exponent) + 1)) return false;
    }
    return true;
}

fn long chernick_carmichael_least_multiplier(long* input, usz length)
    @export("chernick_carmichael_least_multiplier") {
    if (input == null || length != 1) return -1;
    long n = input[0];
    if (n < 3 || n > 9) return -1;

    long step = 1;
    if (n > 4) step = 1L << (n - 4);
    if (n > 5) step *= 5;

    for (long multiplier = step; multiplier <= MAX_MULTIPLIER; multiplier += step) {
        if (has_prime_factors(n, multiplier)) return multiplier;
    }
    return -1;
}
