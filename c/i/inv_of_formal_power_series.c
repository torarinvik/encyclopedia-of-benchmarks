#include <stddef.h>
#include <stdint.h>

#define FPS_MODULUS INT64_C(998244353)
#define FPS_MAX_N ((size_t)64)
#define FPS_MAX_INPUT ((size_t)66)

static int64_t fps_pow_mod(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % FPS_MODULUS;
        base = base * base % FPS_MODULUS;
        exponent >>= 1;
    }
    return result;
}

static void fps_store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t inv_of_formal_power_series(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > FPS_MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > (int64_t)FPS_MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= FPS_MODULUS) return -1;
    if (input[1] == 0) return -1;
    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;

    int64_t inverse[FPS_MAX_N] = {0};
    const int64_t inverse_constant = fps_pow_mod(input[1], FPS_MODULUS - 2);
    inverse[0] = inverse_constant;
    for (size_t degree = 1; degree < n; ++degree) {
        int64_t sum = 0;
        for (size_t i = 1; i <= degree; ++i)
            sum = (sum + input[i + 1] * inverse[degree - i]) % FPS_MODULUS;
        inverse[degree] = (FPS_MODULUS - inverse_constant * sum % FPS_MODULUS) % FPS_MODULUS;
    }
    for (size_t i = 0; i < n; ++i) fps_store_le(output, 8 * i, inverse[i]);
    return (int64_t)bytes;
}
