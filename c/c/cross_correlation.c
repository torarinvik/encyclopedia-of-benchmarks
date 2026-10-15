#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)((bits >> (8 * byte)) & 0xffu);
    }
}

int64_t cross_correlation(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 4 || length > 66) return -1;
    const int64_t raw_x_count = values[0];
    const int64_t raw_y_count = values[1];
    if (raw_x_count < 1 || raw_x_count > 32 || raw_y_count < 1 || raw_y_count > 32) return -1;
    const size_t x_count = (size_t)raw_x_count;
    const size_t y_count = (size_t)raw_y_count;
    if (length != x_count + y_count + 2) return -1;
    for (size_t i = 0; i < x_count + y_count; ++i) {
        if (values[i + 2] < -1000000 || values[i + 2] > 1000000) return -1;
    }
    const size_t result_count = x_count + y_count - 1;
    const size_t byte_count = 8 * result_count;
    if (output == NULL || capacity < byte_count) return -2;

    size_t y_start = y_count;
    for (size_t index = 0; index < result_count; ++index) {
        if (index < y_count) --y_start;
        const size_t k_min = index >= y_count - 1 ? index - (y_count - 1) : 0;
        const size_t k_max = index < x_count ? index : x_count - 1;
        int64_t sum = 0;
        for (size_t k = k_min; k <= k_max; ++k) {
            const size_t y_index = y_start + (k - k_min);
            sum += values[k + 2] * values[x_count + y_index + 2];
        }
        store_i64_le(output, index * 8, sum);
    }
    return (int64_t)byte_count;
}
