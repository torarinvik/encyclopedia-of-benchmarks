#include <stddef.h>
#include <stdint.h>

#define FPS_MODULUS INT64_C(998244353)
#define FPS_MAX_N ((size_t)16)
#define FPS_MAX_INPUT ((size_t)34)

static void fps_store_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t composition_of_formal_power_series(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > FPS_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)FPS_MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;
    for (size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= FPS_MODULUS) return -1;
    if (input[1 + n] != 0) return -1;
    const size_t bytes = 8 * n;
    if (output == NULL || capacity < bytes) return -2;

    int64_t composed[FPS_MAX_N] = {0};
    for (size_t outer = n; outer > 0; --outer) {
        for (size_t bound = n; bound > 1; --bound) {
            const size_t degree = bound - 1;
            int64_t sum = 0;
            for (size_t inner_degree = 1; inner_degree <= degree; ++inner_degree)
                sum = (sum + composed[degree - inner_degree] * input[1 + n + inner_degree]) % FPS_MODULUS;
            composed[degree] = sum;
        }
        composed[0] = input[outer];
    }
    for (size_t i = 0; i < n; ++i) fps_store_le(output, 8 * i, composed[i]);
    return (int64_t)bytes;
}
