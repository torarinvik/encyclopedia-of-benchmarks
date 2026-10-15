#include <stddef.h>
#include <stdint.h>

/* Write the minimal-width ASCII binary form of n ^ (n >> 1). */
int64_t decimal_to_gray(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 0) return -1;

    const int64_t gray = value ^ (value >> 1);
    size_t width = 1;
    for (int64_t remaining = gray; remaining > 1; remaining /= 2) ++width;
    if (output == NULL || output_capacity < width) return -2;

    size_t position = width;
    for (int64_t remaining = gray; position > 0; remaining /= 2)
        output[--position] = (uint8_t)('0' + remaining % 2);
    return (int64_t)width;
}
