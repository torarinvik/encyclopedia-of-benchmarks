#include <stddef.h>
#include <stdint.h>

#define FPS_MODULUS INT64_C(998244353)
#define FPS_MIN_N ((size_t)2)
#define FPS_MAX_N ((size_t)16)
#define FPS_MAX_INPUT ((size_t)18)

static int64_t fps_mod_pow(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % FPS_MODULUS;
        base = base * base % FPS_MODULUS;
        exponent /= 2;
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

int64_t compositional_inverse_of_formal_power_series(const int64_t *input,
    size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < FPS_MIN_N + 1 || length > FPS_MAX_INPUT) return -1;
    if (input[0] < (int64_t)FPS_MIN_N || input[0] > (int64_t)FPS_MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= FPS_MODULUS) return -1;
    if (input[1] != 0 || input[2] == 0) return -1;
    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;

    int64_t powers[FPS_MAX_N * FPS_MAX_N] = {0};
    int64_t inverse_series[FPS_MAX_N] = {0};
    const int64_t inverse_linear = fps_mod_pow(input[2], FPS_MODULUS - 2);
    inverse_series[1] = inverse_linear;
    powers[FPS_MAX_N + 1] = inverse_linear;
    for (size_t degree = 2; degree < n; ++degree) {
        for (size_t power = 2; power <= degree; ++power) {
            int64_t coefficient = 0;
            for (size_t split = 1; split < degree; ++split)
                coefficient = (coefficient + powers[(power - 1) * FPS_MAX_N + degree - split] *
                               inverse_series[split]) % FPS_MODULUS;
            powers[power * FPS_MAX_N + degree] = coefficient;
        }
        int64_t composed_coefficient = 0;
        for (size_t power = 2; power <= degree; ++power)
            composed_coefficient = (composed_coefficient + input[power + 1] *
                                    powers[power * FPS_MAX_N + degree]) % FPS_MODULUS;
        inverse_series[degree] = (FPS_MODULUS - composed_coefficient) * inverse_linear % FPS_MODULUS;
        powers[FPS_MAX_N + degree] = inverse_series[degree];
    }
    for (size_t i = 0; i < n; ++i) fps_store_le(output, 8 * i, inverse_series[i]);
    return (int64_t)bytes;
}
