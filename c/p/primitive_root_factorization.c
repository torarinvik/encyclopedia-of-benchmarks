#include <stddef.h>
#include <stdint.h>

static int is_prime(int64_t value) {
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return 0;
    return 1;
}

static int64_t power_mod(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

int64_t primitive_root_factorization(const int64_t *input, size_t length) {
    if (input == NULL || length != 1 || input[0] < 2 || input[0] > 4093 || !is_prime(input[0])) return -1;
    const int64_t prime = input[0];
    if (prime == 2) return 1;

    int64_t factors[16];
    size_t factor_count = 0;
    int64_t remaining = prime - 1;
    for (int64_t divisor = 2; divisor * divisor <= remaining; ++divisor) {
        if (remaining % divisor == 0) {
            factors[factor_count++] = divisor;
            do { remaining /= divisor; } while (remaining % divisor == 0);
        }
    }
    if (remaining > 1) factors[factor_count++] = remaining;

    for (int64_t candidate = 2; candidate < prime; ++candidate) {
        int valid = 1;
        for (size_t index = 0; index < factor_count; ++index) {
            if (power_mod(candidate, (prime - 1) / factors[index], prime) == 1) {
                valid = 0;
                break;
            }
        }
        if (valid) return candidate;
    }
    return -1;
}
