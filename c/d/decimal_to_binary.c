/* Write the most-significant-first binary representation of a nonnegative i64. */
#include <stddef.h>
#include <stdint.h>

int64_t decimal_to_binary(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 0) return -1;

    size_t width = 1;
    for (int64_t remaining = value; remaining > 1; remaining /= 2) ++width;
    if (output == NULL || output_capacity < width) return -2;

    size_t position = width;
    for (int64_t remaining = value; position > 0; remaining /= 2) {
        output[--position] = (uint8_t)('0' + remaining % 2);
    }
    return (int64_t)width;
}
