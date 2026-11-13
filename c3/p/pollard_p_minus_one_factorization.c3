module pollard_p_minus_one_factorization;

const usz MAX_PRIMES = 18;
const long[MAX_PRIMES] SMALL_PRIMES = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61};

fn long gcd_i64(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long pow_mod_i64(long base, long exponent, long modulus) {
    long result = 1;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long pollard_p_minus_one_factorization(long* input, usz length) @export("pollard_p_minus_one_factorization") {
    if (input == null || length != 3) return -1;
    long number = input[0], bound = input[1], initial = input[2];
    if (number < 2 || number > 1000000000 || bound < 2 || bound > 64 || initial < 1 || initial >= number) return -1;
    long divisor = gcd_i64(initial, number);
    if (divisor > 1) return divisor;
    long state = initial;
    for (usz i = 0; i < MAX_PRIMES; i++) {
        long prime = SMALL_PRIMES[i];
        if (prime > bound) break;
        long exponent = prime;
        while (exponent <= bound / prime) exponent *= prime;
        state = pow_mod_i64(state, exponent, number);
        long difference = state >= 1 ? state - 1 : 1 - state;
        divisor = gcd_i64(difference, number);
        if (divisor > 1) return divisor < number ? divisor : 0;
    }
    return 0;
}
