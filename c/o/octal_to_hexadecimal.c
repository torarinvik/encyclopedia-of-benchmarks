/* Convert a most-significant-first octal digit array to radix 16 text. */
#include <stddef.h>
#include <stdint.h>

int64_t octal_to_hexadecimal(const int64_t *digits, size_t length, uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > 21) return -1;
    int64_t value = 0;
    for (size_t index = 0; index < length; ++index) {
        if (digits[index] < 0 || digits[index] > 7) return -1;
        value = value * 8 + digits[index];
    }
    size_t width = 1;
    for (int64_t remaining = value; remaining >= 16; remaining /= 16) ++width;
    if (output_capacity < width) return -2;
    size_t position = width;
    int64_t remaining = value;
    while (position > 0) {
        --position;
        int64_t digit = remaining % 16;
        output[position] = (uint8_t)(digit < 10 ? '0' + digit : 'a' + digit - 10);
        remaining /= 16;
    }
    return (int64_t)width;
}
