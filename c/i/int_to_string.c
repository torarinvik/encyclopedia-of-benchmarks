/* Convert a uint16 value to lowercase digits in a base from 2 through 16. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUE 65535
#define MAX_DIGITS 16

int64_t int_to_string(int64_t packed, uint8_t *output, size_t output_capacity)
{
    if (packed < 0) return -1;
    const int64_t value = packed / 15;
    const int64_t base = packed % 15 + 2;
    if (value > MAX_VALUE) return -1;
    static const uint8_t symbols[] = "0123456789abcdef";
    uint8_t digits[MAX_DIGITS];
    size_t count = 0;
    int64_t remaining = value;
    do {
        digits[count++] = symbols[remaining % base];
        remaining /= base;
    } while (remaining != 0);
    const size_t required = count + 1;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t i = 0; i < count; ++i) output[i] = digits[count - i - 1];
    output[count] = 0;
    return (int64_t)required;
}
