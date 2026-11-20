module primitive_root_factorization;

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor * divisor <= value; divisor++)
        if (value % divisor == 0) return false;
    return true;
}

fn long power_mod(long base, long exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long primitive_root_factorization(long* input, usz length) @export("primitive_root_factorization") {
    if (input == null || length != 1 || input[0] < 2 || input[0] > 4093 || !is_prime(input[0])) return -1;
    long prime = input[0];
    if (prime == 2) return 1;

    long[16] factors;
    usz factor_count = 0;
    long remaining = prime - 1;
    for (long divisor = 2; divisor * divisor <= remaining; divisor++) {
        if (remaining % divisor == 0) {
            factors[factor_count++] = divisor;
            remaining /= divisor;
            while (remaining % divisor == 0) remaining /= divisor;
        }
    }
    if (remaining > 1) factors[factor_count++] = remaining;

    for (long candidate = 2; candidate < prime; candidate++) {
        bool valid = true;
        for (usz index = 0; index < factor_count; index++) {
            if (power_mod(candidate, (prime - 1) / factors[index], prime) == 1) {
                valid = false;
                break;
            }
        }
        if (valid) return candidate;
    }
    return -1;
}
