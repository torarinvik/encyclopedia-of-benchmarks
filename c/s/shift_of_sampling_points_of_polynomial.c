#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 16, MAX_INPUT = 20 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t mod_pow(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
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

int64_t shift_of_sampling_points_of_polynomial(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    const int64_t start = input[2];
    if (length != n + 3 || start < 0 || start >= MODULUS) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 3] < 0 || input[i + 3] >= MODULUS) return -1;

    const size_t bytes = 8 * m;
    if (output == NULL || capacity < bytes) return -2;

    int64_t differences[MAX_N], newton[MAX_N], factorial[MAX_N], inverse_factorial[MAX_N];
    for (size_t i = 0; i < n; ++i) differences[i] = input[i + 3];
    factorial[0] = 1;
    for (size_t k = 1; k < n; ++k) factorial[k] = factorial[k - 1] * (int64_t)k % MODULUS;
    inverse_factorial[n - 1] = mod_pow(factorial[n - 1], MODULUS - 2);
    for (size_t k = n - 1; k > 0; --k)
        inverse_factorial[k - 1] = inverse_factorial[k] * (int64_t)k % MODULUS;
    for (size_t k = 0; k < n; ++k) {
        newton[k] = differences[0] * inverse_factorial[k] % MODULUS;
        for (size_t i = 0; i + k + 1 < n; ++i) {
            differences[i] = differences[i + 1] - differences[i];
            if (differences[i] < 0) differences[i] += MODULUS;
        }
    }

    for (size_t offset = 0; offset < m; ++offset) {
        int64_t x = start + (int64_t)offset;
        if (x >= MODULUS) x -= MODULUS;
        int64_t basis = 1, value = 0;
        for (size_t k = 0; k < n; ++k) {
            value = (value + newton[k] * basis) % MODULUS;
            int64_t factor = x - (int64_t)k;
            if (factor < 0) factor += MODULUS;
            basis = basis * factor % MODULUS;
        }
        store_le(output, 8 * offset, value);
    }
    return (int64_t)bytes;
}
