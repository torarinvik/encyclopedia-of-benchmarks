/* Write lowercase hexadecimal digits of a nonnegative signed 64-bit input. */
#include <stddef.h>
#include <stdint.h>

int64_t decimal_to_hexadecimal(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 0) return -1;
    size_t width = 1;
    for (int64_t remaining = value; remaining >= 16; remaining /= 16) ++width;
    if (output == NULL || output_capacity < width) return -2;
    size_t position = width;
    for (int64_t remaining = value; position > 0; remaining /= 16) {
        const int64_t digit = remaining % 16;
        output[--position] = (uint8_t)(digit < 10 ? '0' + digit : 'a' + digit - 10);
    }
    return (int64_t)width;
}
