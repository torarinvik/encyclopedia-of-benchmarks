#include <stddef.h>
#include <stdint.h>

static int64_t totient(int64_t value) {
    int64_t result = value;
    int64_t remaining = value;
    if (remaining % 2 == 0) {
        result -= result / 2;
        do { remaining /= 2; } while (remaining % 2 == 0);
    }
    for (int64_t factor = 3; factor <= remaining / factor; factor += 2) {
        if (remaining % factor == 0) {
            result -= result / factor;
            do { remaining /= factor; } while (remaining % factor == 0);
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

static int64_t power_capped(int64_t base, int64_t exponent, int64_t cap) {
    int64_t result = 1;
    int64_t factor = base < cap ? base : cap;
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

static int64_t tower_capped(int64_t base, int64_t height, int64_t cap) {
    if (height == 0) return 1 < cap ? 1 : cap;
    if (base == 0) return height % 2 == 0 ? 1 : 0;
    if (base == 1) return 1 < cap ? 1 : cap;
    int64_t value = 1;
    if (value >= cap) return cap;
    while (height > 0) {
        value = power_capped(base, value, cap);
        if (value >= cap) return cap;
        --height;
    }
    return value;
}

static int64_t modular_power(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1 % modulus;
    base %= modulus;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = (result * base) % modulus;
        exponent /= 2;
        base = (base * base) % modulus;
    }
    return result;
}

static int64_t tetration(int64_t base, int64_t height, int64_t modulus) {
    if (modulus == 1) return 0;
    if (height == 0) return 1 % modulus;
    if (height == 1) return base % modulus;
    const int64_t exponent_modulus = totient(modulus);
    int64_t exponent = tetration(base, height - 1, exponent_modulus);
    if (tower_capped(base, height - 1, exponent_modulus) >= exponent_modulus)
        exponent += exponent_modulus;
    return modular_power(base, exponent, modulus);
}

int64_t tetration_mod(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return -1;
    const int64_t base = input[0];
    const int64_t height = input[1];
    const int64_t modulus = input[2];
    if (base < 0 || base > INT64_C(1000000000)
        || height < 0 || height > INT64_C(1000000000)
        || modulus < 1 || modulus > INT64_C(1000000000)) return -1;
    return tetration(base, height, modulus);
}
