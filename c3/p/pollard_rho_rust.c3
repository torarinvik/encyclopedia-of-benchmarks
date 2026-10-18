module pollard_rho_rust;

const long MAX_NUM = 1000000000L;
const long U32_MOD = 4294967296L;
const long BATCH = 32L;
const long CUTOFF = 262144L;

fn long gcd_nonnegative(long left, long right) {
    while (left != 0L) {
        long remainder = right % left;
        right = left;
        left = remainder;
    }
    return right;
}

fn long mod_power(long base, long power, long modulus) {
    base = base % modulus;
    if (base == 0L) return 0L;
    long result = 1L;
    while (power > 0L) {
        if (power % 2L != 0L) result = (result * base) % modulus;
        base = (base * base) % modulus;
        power = power / 2L;
    }
    return result;
}

fn bool passes_base(long number, long base) {
    long odd_power = number - 1L;
    long two_power = 0L;
    while (odd_power % 2L == 0L) { odd_power = odd_power / 2L; two_power++; }
    long value = mod_power(base, odd_power, number);
    if (value == 1L || value == number - 1L) return true;
    for (long r = 1L; r < two_power; r++) {
        value = (value * value) % number;
        if (value == number - 1L) return true;
    }
    return false;
}

fn bool probable_prime(long number) {
    if (number <= 4L) return number == 2L || number == 3L;
    if (number == 5L || number == 7L) return true;
    return passes_base(number, 2L) && passes_base(number, 3L) && passes_base(number, 5L) && passes_base(number, 7L);
}

fn long advance(long x, long c, long number) { return (x * x + c) % number; }

fn long brent_factor(long number, long x0, long c) {
    long x = x0, x_start = 0L, y = 0L, remainder = 1L, current_gcd = 1L;
    long max_iterations = 1L;
    while (current_gcd == 1L) {
        y = x;
        for (long i = 1L; i < max_iterations; i++) x = advance(x, c, number);
        long big_iteration = 0L;
        while (big_iteration < max_iterations && current_gcd == 1L) {
            x_start = x;
            long small_iteration = 0L;
            while (small_iteration < BATCH && small_iteration < max_iterations - big_iteration) {
                small_iteration++;
                x = advance(x, c, number);
                long difference = x - y;
                if (difference < 0L) difference = -difference;
                remainder = (remainder * difference) % number;
            }
            current_gcd = gcd_nonnegative(remainder, number);
            big_iteration += BATCH;
        }
        max_iterations *= 2L;
        if (max_iterations > CUTOFF) break;
    }
    if (current_gcd == number) {
        while (current_gcd == 1L) {
            x_start = advance(x_start, c, number);
            long difference = x_start - y;
            if (difference < 0L) difference = -difference;
            current_gcd = gcd_nonnegative(difference, number);
        }
    }
    return current_gcd;
}

fn long pollard_rho_rust(long* input, usz length) @export("pollard_rho_rust") {
    if (input == null || length != 3) return -1L;
    long number = input[0];
    long state = input[1];
    long restart_limit = input[2];
    if (number < 2L || number > MAX_NUM || state < 0L || state >= U32_MOD || restart_limit < 1L || restart_limit > 16L) return -1L;
    if (probable_prime(number)) return number;

    for (long restart = 0L; restart < restart_limit; restart++) {
        state = (1103515245L * state + 12345L) % U32_MOD;
        long high_x = state;
        state = (1103515245L * state + 12345L) % U32_MOD;
        long low_x = state;
        long x0 = ((high_x % (number - 3L)) * (U32_MOD % (number - 3L)) + low_x % (number - 3L)) % (number - 3L) + 2L;
        state = (1103515245L * state + 12345L) % U32_MOD;
        long high_c = state;
        state = (1103515245L * state + 12345L) % U32_MOD;
        long low_c = state;
        long c = ((high_c % (number - 2L)) * (U32_MOD % (number - 2L)) + low_c % (number - 2L)) % (number - 2L) + 1L;
        long factor = brent_factor(number, x0, c);
        if (factor != 1L && factor != number) return factor;
    }
    return 0L;
}
