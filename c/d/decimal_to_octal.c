/* Write the octal digits of a nonnegative signed 64-bit input. */
#include <stddef.h>
#include <stdint.h>

int64_t decimal_to_octal(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 0) return -1;
    size_t width = 1;
    for (int64_t remaining = value; remaining >= 8; remaining /= 8) ++width;
    if (output == NULL || output_capacity < width) return -2;
    size_t position = width;
    for (int64_t remaining = value; position > 0; remaining /= 8)
        output[--position] = (uint8_t)('0' + remaining % 8);
    return (int64_t)width;
}
