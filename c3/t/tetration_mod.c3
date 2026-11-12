module tetration_mod;

fn long totient(long value) {
    long result = value;
    long remaining = value;
    if (remaining % 2 == 0) {
        result -= result / 2;
        do { remaining /= 2; } while (remaining % 2 == 0);
    }
    for (long factor = 3; factor <= remaining / factor; factor += 2) {
        if (remaining % factor == 0) {
            result -= result / factor;
            do { remaining /= factor; } while (remaining % factor == 0);
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

fn long power_capped(long base, long exponent, long cap) {
    long result = 1;
    long factor = base < cap ? base : cap;
    while (exponent > 0) {
        if (exponent % 2 != 0) {
            result *= factor;
            if (result >= cap) return cap;
        }
        exponent /= 2;
        if (exponent > 0) {
            factor *= factor;
            if (factor >= cap) factor = cap;
        }
    }
    return result;
}

fn long tower_capped(long base, long height, long cap) {
    if (height == 0) return 1 < cap ? 1 : cap;
    if (base == 0) return height % 2 == 0 ? 1 : 0;
    if (base == 1) return 1 < cap ? 1 : cap;
    long value = 1;
    if (value >= cap) return cap;
    while (height > 0) {
        value = power_capped(base, value, cap);
        if (value >= cap) return cap;
        height -= 1;
    }
    return value;
}

fn long modular_power(long base, long exponent, long modulus) {
    long result = 1 % modulus;
    base %= modulus;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = (result * base) % modulus;
        exponent /= 2;
        base = (base * base) % modulus;
    }
    return result;
}

fn long tetration(long base, long height, long modulus) {
    if (modulus == 1) return 0;
    if (height == 0) return 1 % modulus;
    if (height == 1) return base % modulus;
    long exponent_modulus = totient(modulus);
    long exponent = tetration(base, height - 1, exponent_modulus);
    if (tower_capped(base, height - 1, exponent_modulus) >= exponent_modulus)
        exponent += exponent_modulus;
    return modular_power(base, exponent, modulus);
}

fn long tetration_mod(long* input, usz length) @export("tetration_mod") {
    if (input == null || length != 3) return -1;
    long base = input[0];
    long height = input[1];
    long modulus = input[2];
    if (base < 0 || base > 1000000000 || height < 0 || height > 1000000000
        || modulus < 1 || modulus > 1000000000) return -1;
    return tetration(base, height, modulus);
}
