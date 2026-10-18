#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-INT64_C(1))
#define MAX_PACKED_LENGTH 21
#define FACTOR_BASE INT64_C(65536)

static int64_t gcd_i64(int64_t a, int64_t b)
{
    if (a < 0) a = -a;
    if (b < 0) b = -b;
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static int64_t power_mod_i64(int64_t base, int64_t exponent, int64_t modulus)
{
    int64_t result = 1;
    int64_t power = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * power) % modulus;
        power = (power * power) % modulus;
        exponent /= 2;
    }
    return result;
}

int64_t rsa_factorization(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 4 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const int64_t d = packed[0], e = packed[1], modulus = packed[2], attempts = packed[3];
    if (d < 1 || d > 1000000 || e < 1 || e > 1000000 ||
        modulus < 3 || modulus > 65535 || (modulus & 1) == 0 ||
        attempts < 1 || attempts > 16 || length != (size_t)(4 + attempts)) return INVALID_RESULT;
    const int64_t k = d * e - 1;
    if (k <= 0 || (k & 1) != 0) return INVALID_RESULT;
    for (int64_t i = 0; i < attempts; ++i) {
        const int64_t base = packed[4 + (size_t)i];
        if (base < 2 || base > modulus - 1) return INVALID_RESULT;
    }

    for (int64_t i = 0; i < attempts; ++i) {
        const int64_t base = packed[4 + (size_t)i];
        int64_t t = k;
        while ((t & 1) == 0) {
            t /= 2;
            const int64_t x = power_mod_i64(base, t, modulus);
            const int64_t factor = gcd_i64(x - 1, modulus);
            if (x > 1 && factor > 1) {
                int64_t other = modulus / factor;
                int64_t p = factor, q = other;
                if (p > q) { const int64_t temporary = p; p = q; q = temporary; }
                return p * FACTOR_BASE + q;
            }
        }
    }
    return INVALID_RESULT;
}
