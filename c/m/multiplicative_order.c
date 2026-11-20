#include <stddef.h>
#include <stdint.h>

static int64_t gcd_i64(int64_t a, int64_t b) {
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static int64_t pow_mod_i64(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    base %= modulus;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent /= 2;
    }
    return result;
}

static int64_t totient_i64(int64_t value) {
    int64_t remaining = value;
    int64_t result = value;
    for (int64_t prime = 2; prime * prime <= remaining; ++prime) {
        if (remaining % prime == 0) {
            result = result / prime * (prime - 1);
            do { remaining /= prime; } while (remaining % prime == 0);
        }
    }
    if (remaining > 1) result = result / remaining * (remaining - 1);
    return result;
}

static int64_t reduce_order(int64_t base, int64_t modulus, int64_t order) {
    int64_t remaining = order;
    for (int64_t prime = 2; prime * prime <= remaining; ++prime) {
        if (remaining % prime == 0) {
            do { remaining /= prime; } while (remaining % prime == 0);
            while (order % prime == 0 && pow_mod_i64(base, order / prime, modulus) == 1)
                order /= prime;
        }
    }
    if (remaining > 1) {
        while (order % remaining == 0 && pow_mod_i64(base, order / remaining, modulus) == 1)
            order /= remaining;
    }
    return order;
}

int64_t multiplicative_order(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t base = input[0], modulus = input[1];
    if (modulus < 2 || modulus > 1000 || base < 0 || base >= modulus) return -1;
    if (gcd_i64(base, modulus) != 1) return 0;
    return reduce_order(base, modulus, totient_i64(modulus));
}
