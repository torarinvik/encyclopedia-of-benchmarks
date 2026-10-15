/* Format a bounded multiplication table as source-faithful ASCII lines. */
#include <stddef.h>
#include <stdint.h>

static size_t decimal_length(int64_t value)
{
    size_t length = 1;
    if (value < 0) { ++length; value = -value; }
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

static size_t append_decimal(uint8_t *output, size_t position, int64_t value)
{
    if (value < 0) { output[position++] = '-'; value = -value; }
    uint8_t reversed[20];
    size_t count = 0;
    do { reversed[count++] = (uint8_t)('0' + value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = reversed[--count];
    return position;
}

int64_t print_multiplication_table(const int64_t *input, size_t length,
                                   uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 2) return -1;
    const int64_t number = input[0];
    const int64_t terms = input[1];
    if (number < -1000000 || number > 1000000 || terms < -20 || terms > 20) return -1;
    size_t required = terms > 0 ? (size_t)terms - 1 : 0;
    for (int64_t multiplier = 1; multiplier <= terms; ++multiplier) {
        const int64_t product = number * multiplier;
        required += decimal_length(number) + 3 + decimal_length(multiplier) + 3 + decimal_length(product);
    }
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    size_t position = 0;
    for (int64_t multiplier = 1; multiplier <= terms; ++multiplier) {
        if (multiplier > 1) output[position++] = '\n';
        position = append_decimal(output, position, number);
        output[position++] = ' '; output[position++] = '*'; output[position++] = ' ';
        position = append_decimal(output, position, multiplier);
        output[position++] = ' '; output[position++] = '='; output[position++] = ' ';
        position = append_decimal(output, position, number * multiplier);
    }
    return (int64_t)position;
}
