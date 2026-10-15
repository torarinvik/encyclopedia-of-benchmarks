/* Lyndon factorization using Duval's linear-time algorithm. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static int valid_input(const int64_t *values, size_t length) {
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return 0;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 0 || values[i] > 127) return 0;
    }
    return 1;
}

static size_t factor_count(const int64_t *values, size_t length) {
    size_t start = 0, count = 0;
    while (start < length) {
        size_t end = start + 1, repeat = start;
        while (end < length && values[repeat] <= values[end]) {
            if (values[repeat] < values[end]) repeat = start;
            else ++repeat;
            ++end;
        }
        const size_t factor_length = end - repeat;
        while (start <= repeat) {
            ++count;
            start += factor_length;
        }
    }
    return count;
}

static void store_u32_le(uint8_t *output, size_t offset, size_t value) {
    const uint32_t packed = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(packed >> (8 * byte));
}

static void write_factors(const int64_t *values, size_t length, uint8_t *output) {
    size_t start = 0, factor_index = 0;
    while (start < length) {
        size_t end = start + 1, repeat = start;
        while (end < length && values[repeat] <= values[end]) {
            if (values[repeat] < values[end]) repeat = start;
            else ++repeat;
            ++end;
        }
        const size_t factor_length = end - repeat;
        while (start <= repeat) {
            store_u32_le(output, 4 * factor_index, factor_length);
            ++factor_index;
            start += factor_length;
        }
    }
}

int64_t duval_algorithm(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity) {
    if (!valid_input(values, length)) return -1;
    const size_t count = factor_count(values, length);
    const size_t required = 4 * count;
    if (required == 0) return 0;
    if (output == NULL || output_capacity < required) return -2;
    write_factors(values, length, output);
    return (int64_t)count;
}
