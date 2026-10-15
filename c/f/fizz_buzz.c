#include <stddef.h>
#include <stdint.h>

static size_t token_length(int64_t value)
{
    if (value % 15 == 0) return 8;
    if (value % 3 == 0 || value % 5 == 0) return 4;
    if (value >= 100) return 3;
    if (value >= 10) return 2;
    return 1;
}

static size_t append_number(int64_t value, uint8_t *output, size_t position)
{
    if (value >= 100) {
        output[position++] = (uint8_t)('0' + value / 100);
        value %= 100;
        output[position++] = (uint8_t)('0' + value / 10);
        output[position++] = (uint8_t)('0' + value % 10);
    } else if (value >= 10) {
        output[position++] = (uint8_t)('0' + value / 10);
        output[position++] = (uint8_t)('0' + value % 10);
    } else {
        output[position++] = (uint8_t)('0' + value);
    }
    return position;
}

int64_t fizz_buzz(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 1 || value > 512) return -1;
    size_t width = 0;
    for (int64_t current = 1; current <= value; ++current) width += token_length(current) + 1;
    if (output == NULL || output_capacity < width) return -2;
    size_t position = 0;
    for (int64_t current = 1; current <= value; ++current) {
        if (current % 15 == 0) {
            output[position++] = 'F'; output[position++] = 'i'; output[position++] = 'z'; output[position++] = 'z';
            output[position++] = 'B'; output[position++] = 'u'; output[position++] = 'z'; output[position++] = 'z';
        } else if (current % 3 == 0) {
            output[position++] = 'F'; output[position++] = 'i'; output[position++] = 'z'; output[position++] = 'z';
        } else if (current % 5 == 0) {
            output[position++] = 'B'; output[position++] = 'u'; output[position++] = 'z'; output[position++] = 'z';
        } else {
            position = append_number(current, output, position);
        }
        output[position++] = ' ';
    }
    return (int64_t)position;
}
