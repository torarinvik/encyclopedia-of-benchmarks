#include <stddef.h>
#include <stdint.h>

#define MIN_MODULUS INT64_C(2)
#define MAX_MODULUS INT64_C(255)
#define MIN_ATTEMPTS INT64_C(1)
#define MAX_ATTEMPTS INT64_C(16)
#define INVALID_RESULT (-INT64_C(1))

static int64_t gcd_i64(int64_t a, int64_t b)
{
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

int64_t shors_algorithm(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 3 || length > 19) return INVALID_RESULT;
    const int64_t modulus = packed[0];
    const int64_t attempts = packed[1];
    if (modulus < MIN_MODULUS || modulus > MAX_MODULUS ||
        attempts < MIN_ATTEMPTS || attempts > MAX_ATTEMPTS ||
        length != (size_t)(2 + attempts)) return INVALID_RESULT;
    for (int64_t index = 0; index < attempts; ++index) {
        const int64_t base = packed[2 + (size_t)index];
        if (base < 2 || base > modulus) return INVALID_RESULT;
    }

    for (int64_t index = 0; index < attempts; ++index) {
        const int64_t base = packed[2 + (size_t)index];
        const int64_t common = gcd_i64(base, modulus);
        if (common != 1) return common;

        int64_t order = 1;
        int64_t power = base % modulus;
        while (power != 1 && order < modulus - 1) {
            power = (power * base) % modulus;
            ++order;
        }
        if (power != 1) return INVALID_RESULT;
        if ((order & 1) != 0) continue;

        int64_t half_power = 1;
        for (int64_t exponent = 0; exponent < order / 2; ++exponent) {
            half_power = (half_power * base) % modulus;
        }
        const int64_t upper = half_power + 1;
        const int64_t lower = half_power - 1;
        if (upper % modulus == 0 || lower % modulus == 0) continue;
        const int64_t upper_gcd = gcd_i64(upper, modulus);
        if (upper_gcd != 1) return upper_gcd;
        return gcd_i64(lower, modulus);
    }
    return INVALID_RESULT;
}
