#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t convolution(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 4 || length > 130) return -1;
    const int64_t raw_a_count = values[0];
    const int64_t raw_b_count = values[1];
    if (raw_a_count < 1 || raw_a_count > 64 || raw_b_count < 1 || raw_b_count > 64) return -1;
    const size_t a_count = (size_t)raw_a_count;
    const size_t b_count = (size_t)raw_b_count;
    if (length != a_count + b_count + 2) return -1;
    for (size_t i = 0; i < a_count + b_count; ++i) {
        if (values[i + 2] < -1000000 || values[i + 2] > 1000000) return -1;
    }
    const size_t result_count = a_count + b_count - 1;
    const size_t byte_count = result_count * 8;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t i = 0; i < result_count; ++i) {
        const size_t k_start = i >= b_count - 1 ? i - (b_count - 1) : 0;
        const size_t k_end = i < a_count ? i : a_count - 1;
        int64_t sum = 0;
        for (size_t k = k_start; k <= k_end; ++k) sum += values[k + 2] * values[a_count + (i - k) + 2];
        store_i64_le(output, i * 8, sum);
    }
    return (int64_t)byte_count;
}
