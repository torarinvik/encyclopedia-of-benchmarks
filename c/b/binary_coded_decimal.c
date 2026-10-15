/* Write the prefixed four-bit-per-decimal-digit BCD representation. */
#include <stddef.h>
#include <stdint.h>

int64_t binary_coded_decimal(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < INT32_MIN || value > INT32_MAX) return -1;
    if (value < 0) value = 0;

    uint8_t digits[10];
    size_t digit_count = 0;
    do {
        digits[digit_count++] = (uint8_t)(value % 10);
        value /= 10;
    } while (value > 0);

    const size_t output_length = 2 + digit_count * 4;
    if (output == NULL || output_capacity < output_length) return -2;
    output[0] = (uint8_t)'0';
    output[1] = (uint8_t)'b';
    size_t position = 2;
    while (digit_count > 0) {
        const uint8_t digit = digits[--digit_count];
        for (int bit = 3; bit >= 0; --bit)
            output[position++] = (uint8_t)('0' + ((digit >> bit) & 1));
    }
    return (int64_t)output_length;
}
