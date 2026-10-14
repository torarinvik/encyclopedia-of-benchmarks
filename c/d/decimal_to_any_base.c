/* Convert a nonnegative signed 64-bit value to base 2 through 36. */
#include <stddef.h>
#include <stdint.h>

int64_t decimal_to_any_base(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 2) return -1;
    const int64_t value = input[0], base = input[1];
    if (value < 0 || base < 2 || base > 36) return -1;
    size_t width = 1;
    for (int64_t remaining = value; remaining >= base; remaining /= base) ++width;
    if (output == NULL || output_capacity < width) return -2;
    size_t position = width;
    int64_t remaining = value;
    while (position > 0) {
        --position;
        const int64_t digit = remaining % base;
        output[position] = (uint8_t)(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= base;
    }
    return (int64_t)width;
}
