#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define BYTES_PER_TRIPLET 12

static void write_i32_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

static size_t enumerate(const int64_t *values, size_t length, uint8_t *output, bool write_output)
{
    size_t count = 0;
    bool has_last = false;
    int64_t last_a = 0, last_b = 0, last_c = 0;
    for (size_t i = 0; i + 2 < length; ++i) {
        for (size_t j = i + 1; j + 1 < length; ++j) {
            for (size_t k = j + 1; k < length; ++k) {
                if (values[i] + values[j] + values[k] != 0) continue;
                if (has_last && values[i] == last_a && values[j] == last_b && values[k] == last_c) continue;
                if (write_output) {
                    const size_t offset = count * BYTES_PER_TRIPLET;
                    write_i32_le(output, offset, values[i]);
                    write_i32_le(output, offset + 4, values[j]);
                    write_i32_le(output, offset + 8, values[k]);
                }
                last_a = values[i]; last_b = values[j]; last_c = values[k]; has_last = true;
                ++count;
            }
        }
    }
    return count;
}

int64_t find_triplets_with_0_sum(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (length > MAX_ITEMS || (length > 0 && input == NULL)) return -1;
    int64_t values[MAX_ITEMS];
    for (size_t i = 0; i < length; ++i) {
        if (input[i] < -100000 || input[i] > 100000) return -1;
        values[i] = input[i];
    }
    for (size_t i = 1; i < length; ++i) {
        const int64_t key = values[i];
        size_t j = i;
        while (j > 0 && values[j - 1] > key) { values[j] = values[j - 1]; --j; }
        values[j] = key;
    }
    const size_t count = enumerate(values, length, NULL, false);
    if (count == 0) return 0;
    const size_t needed = count * BYTES_PER_TRIPLET;
    if (output == NULL || output_capacity < needed) return -2;
    return (int64_t)enumerate(values, length, output, true);
}
