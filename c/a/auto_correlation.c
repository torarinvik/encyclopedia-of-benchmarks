#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)((bits >> (8 * byte)) & 0xffu);
    }
}

int64_t auto_correlation(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2 || length > 65) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 1 || raw_count > 64) return -1;
    const size_t count = (size_t)raw_count;
    if (length != count + 1) return -1;
    for (size_t i = 0; i < count; ++i) {
        if (values[i + 1] < -1000000 || values[i + 1] > 1000000) return -1;
    }
    const size_t result_count = 2 * count - 1;
    const size_t byte_count = 8 * result_count;
    if (output == NULL || capacity < byte_count) return -2;

    size_t y_start = count;
    for (size_t index = 0; index < result_count; ++index) {
        if (index < count) --y_start;
        const size_t k_min = index >= count - 1 ? index - (count - 1) : 0;
        const size_t k_max = index < count ? index : count - 1;
        size_t offset = 0;
        int64_t sum = 0;
        for (size_t k = k_min; k <= k_max; ++k) {
            sum += values[k + 1] * values[y_start + offset + 1];
            ++offset;
        }
        store_i64_le(output, index * 8, sum);
    }
    return (int64_t)byte_count;
}
