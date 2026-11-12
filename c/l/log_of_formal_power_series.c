#include <stddef.h>
#include <stdint.h>

#define FPS_MODULUS INT64_C(998244353)
#define FPS_MAX_N ((size_t)64)
#define FPS_MAX_INPUT ((size_t)66)

static void fps_store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t log_of_formal_power_series(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > FPS_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)FPS_MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= FPS_MODULUS) return -1;
    if (input[1] != 1) return -1;
    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;

    int64_t integer_inverse[FPS_MAX_N] = {0};
    int64_t logarithm[FPS_MAX_N] = {0};
    if (n > 1) integer_inverse[1] = 1;
    for (size_t k = 2; k < n; ++k)
        integer_inverse[k] = FPS_MODULUS - (FPS_MODULUS / (int64_t)k) * integer_inverse[(size_t)(FPS_MODULUS % (int64_t)k)] % FPS_MODULUS;
    for (size_t degree = 1; degree < n; ++degree) {
        int64_t numerator = (int64_t)degree * input[degree + 1] % FPS_MODULUS;
        for (size_t i = 1; i < degree; ++i) {
            int64_t term = (int64_t)i * logarithm[i] % FPS_MODULUS;
            term = term * input[degree - i + 1] % FPS_MODULUS;
            numerator = (numerator - term) % FPS_MODULUS;
            if (numerator < 0) numerator += FPS_MODULUS;
        }
        logarithm[degree] = numerator * integer_inverse[degree] % FPS_MODULUS;
    }
    for (size_t i = 0; i < n; ++i) fps_store_le(output, 8 * i, logarithm[i]);
    return (int64_t)bytes;
}
