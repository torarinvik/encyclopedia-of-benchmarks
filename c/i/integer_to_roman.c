/* Encode an integer in canonical uppercase Roman numerals. */
#include <stddef.h>
#include <stdint.h>

static size_t roman_digit_length(int64_t digit)
{
    if (digit == 4 || digit == 9) return 2;
    if (digit >= 5) return (size_t)(digit - 4);
    return (size_t)digit;
}

static size_t append_roman_digit(int64_t digit, uint8_t one, uint8_t five, uint8_t ten,
                                 uint8_t *output, size_t position)
{
    if (digit == 9) { output[position++] = one; output[position++] = ten; return position; }
    if (digit >= 5) { output[position++] = five; digit -= 5; }
    if (digit == 4) { output[position++] = one; output[position++] = five; return position; }
    while (digit-- > 0) output[position++] = one;
    return position;
}

int64_t integer_to_roman(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 1 || value > 3999) return -1;
    const size_t width = (size_t)(value / 1000) +
        roman_digit_length((value / 100) % 10) +
        roman_digit_length((value / 10) % 10) + roman_digit_length(value % 10);
    if (output == NULL || output_capacity < width) return -2;

    size_t position = 0;
    for (int64_t count = value / 1000; count > 0; --count) output[position++] = 'M';
    position = append_roman_digit((value / 100) % 10, 'C', 'D', 'M', output, position);
    position = append_roman_digit((value / 10) % 10, 'X', 'L', 'C', output, position);
    position = append_roman_digit(value % 10, 'I', 'V', 'X', output, position);
    return (int64_t)position;
}
