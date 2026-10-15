/* Emit the one-based hexagonal number sequence as little-endian i64 values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024
#define BYTES_PER_VALUE 8

static void store_i64_le(uint8_t *output, size_t position, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t hexagonal_numbers_one_based(int64_t length, uint8_t *output, size_t output_capacity)
{
    if (length < 0 || length > MAX_LENGTH) return -1;
    const size_t n = (size_t)length;
    const size_t required = n * BYTES_PER_VALUE;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < n; ++index) {
        const int64_t i = (int64_t)index + 1;
        store_i64_le(output, index * BYTES_PER_VALUE, i * (2 * i - 1));
    }
    return length;
}
