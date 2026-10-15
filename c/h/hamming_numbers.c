/* Emit the first n positive 5-smooth numbers as little-endian i64 values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 32

int64_t hamming_numbers(const int64_t *input, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > MAX_COUNT) return -1;
    const size_t count = (size_t)input[0];
    const size_t output_bytes = count * 8;
    if (output_capacity < output_bytes || output == NULL) return -2;

    uint64_t values[MAX_COUNT] = {0};
    values[0] = 1;
    size_t i2 = 0, i3 = 0, i5 = 0;
    for (size_t index = 1; index < count; ++index) {
        const uint64_t c2 = values[i2] * 2;
        const uint64_t c3 = values[i3] * 3;
        const uint64_t c5 = values[i5] * 5;
        uint64_t next = c2 < c3 ? c2 : c3;
        if (c5 < next) next = c5;
        values[index] = next;
        if (c2 == next) ++i2;
        if (c3 == next) ++i3;
        if (c5 == next) ++i5;
    }
    for (size_t index = 0; index < count; ++index) {
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(values[index] >> (byte * 8));
    }
    return (int64_t)count;
}
