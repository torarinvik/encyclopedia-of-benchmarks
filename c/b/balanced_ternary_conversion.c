#include <stddef.h>
#include <stdint.h>

enum { MAX_OUTPUT_BYTES = 41 };

int64_t balanced_ternary_conversion(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity)
{
    if (input == NULL || length != 1u) return -1;
    uint8_t reversed[MAX_OUTPUT_BYTES];
    size_t digit_count = 0u;
    int64_t value = input[0];
    if (value == 0) reversed[digit_count++] = (uint8_t)'0';
    while (value != 0) {
        int64_t quotient = value / 3;
        const int64_t remainder = value % 3;
        uint8_t digit;
        if (remainder == 2) { digit = (uint8_t)'Z'; ++quotient; }
        else if (remainder == -2) { digit = (uint8_t)'1'; --quotient; }
        else if (remainder == -1) digit = (uint8_t)'Z';
        else if (remainder == 0) digit = (uint8_t)'0';
        else digit = (uint8_t)'1';
        reversed[digit_count++] = digit;
        value = quotient;
    }
    if (output == NULL || capacity < digit_count) return -2;
    for (size_t index = 0u; index < digit_count; ++index)
        output[index] = reversed[digit_count - index - 1u];
    return (int64_t)digit_count;
}
