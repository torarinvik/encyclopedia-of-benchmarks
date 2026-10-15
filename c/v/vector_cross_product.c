/* Cross two bounded integer vectors and encode components plus magnitude. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t vector_cross_product(const int64_t *input, size_t input_length,
                             uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length != 6) return -1;
    for (size_t i = 0; i < 6; ++i) {
        if (input[i] < -INT64_C(1000000) || input[i] > INT64_C(1000000)) return -1;
    }
    const int64_t x = input[1] * input[5] - input[2] * input[4];
    const int64_t y = -((input[0] * input[5]) - (input[2] * input[3]));
    const int64_t z = input[0] * input[4] - input[1] * input[3];
    const double magnitude = sqrt((double)x * (double)x + (double)y * (double)y + (double)z * (double)z);
    const int64_t magnitude_micro = (int64_t)(magnitude * 1000000.0 + 0.5);
    if (output == NULL || output_capacity < 32) return -2;
    store_i64_le(output, 0, x); store_i64_le(output, 8, y);
    store_i64_le(output, 16, z); store_i64_le(output, 24, magnitude_micro);
    return 32;
}
