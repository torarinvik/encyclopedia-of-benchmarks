module multiplicative_order;

fn long gcd_i64(long a, long b) {
    while (b != 0) { long remainder = a % b; a = b; b = remainder; }
    return a;
}

fn long pow_mod_i64(long base, long exponent, long modulus) {
    long result = 1;
    base %= modulus;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent /= 2;
    }
    return result;
}

fn long totient_i64(long value) {
    long remaining = value, result = value;
    for (long prime = 2; prime * prime <= remaining; prime++) {
        if (remaining % prime == 0) {
            result = result / prime * (prime - 1);
            while (remaining % prime == 0) remaining /= prime;
        }
    }
    if (remaining > 1) result = result / remaining * (remaining - 1);
    return result;
}

fn long reduce_order(long base, long modulus, long order) {
    long remaining = order;
    for (long prime = 2; prime * prime <= remaining; prime++) {
        if (remaining % prime == 0) {
            while (remaining % prime == 0) remaining /= prime;
            while (order % prime == 0 && pow_mod_i64(base, order / prime, modulus) == 1) order /= prime;
        }
    }
    if (remaining > 1)
        while (order % remaining == 0 && pow_mod_i64(base, order / remaining, modulus) == 1) order /= remaining;
    return order;
}

fn long multiplicative_order(long *input, usz length) @export("multiplicative_order") {
    if (input == null || length != 2) return -1;
    long base = input[0], modulus = input[1];
    if (modulus < 2 || modulus > 1000 || base < 0 || base >= modulus) return -1;
    if (gcd_i64(base, modulus) != 1) return 0;
    return reduce_order(base, modulus, totient_i64(modulus));
}
