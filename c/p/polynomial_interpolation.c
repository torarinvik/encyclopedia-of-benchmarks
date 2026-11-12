#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_INPUT = 25 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t normalize(int64_t value)
{
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static int64_t power_mod(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

static void store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t polynomial_interpolation(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;
    const int64_t *xs = input + 1;
    const int64_t *ys = input + 1 + n;
    for (size_t i = 0; i < n; ++i) {
        if (xs[i] < 0 || xs[i] >= MODULUS || ys[i] < 0 || ys[i] >= MODULUS) return -1;
        for (size_t j = 0; j < i; ++j) if (xs[i] == xs[j]) return -1;
    }

    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;
    int64_t result[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        int64_t basis[MAX_N + 1] = {0};
        basis[0] = 1;
        size_t degree = 0;
        int64_t denominator = 1;
        for (size_t j = 0; j < n; ++j) {
            if (j == i) continue;
            denominator = denominator * (xs[i] - xs[j]) % MODULUS;
            int64_t expanded[MAX_N + 1] = {0};
            for (size_t k = 0; k <= degree; ++k) {
                expanded[k] = normalize(expanded[k] - basis[k] * xs[j]);
                expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
            }
            for (size_t k = 0; k <= degree + 1; ++k) basis[k] = expanded[k];
            ++degree;
        }
        const int64_t scale = ys[i] * power_mod(normalize(denominator), MODULUS - 2) % MODULUS;
        for (size_t k = 0; k < n; ++k)
            result[k] = (result[k] + scale * basis[k]) % MODULUS;
    }
    for (size_t i = 0; i < n; ++i) store_le(output, 8 * i, result[i]);
    return (int64_t)bytes;
}
