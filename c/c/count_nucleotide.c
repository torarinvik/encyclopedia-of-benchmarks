/* Count A/C/G/T and return all four counts as an ASCII string. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE_LENGTH 1000

static size_t decimal_length(int64_t value) {
    size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

static size_t write_decimal(uint8_t *output, size_t offset, int64_t value) {
    int64_t divisor = 1;
    while (value / divisor >= 10) divisor *= 10;
    while (divisor > 0) {
        output[offset++] = (uint8_t)('0' + value / divisor);
        value %= divisor;
        divisor /= 10;
    }
    return offset;
}

int64_t count_nucleotide(const int64_t *values, size_t length, uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 1 || length > MAX_SEQUENCE_LENGTH + 1) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_SEQUENCE_LENGTH || length != (size_t)count_value + 1) return -1;
    int64_t count_a = 0, count_c = 0, count_g = 0, count_t = 0;
    for (size_t i = 0; i < (size_t)count_value; ++i) {
        const int64_t codepoint = values[1 + i];
        if (codepoint < 0 || codepoint > 127) return -1;
        if (codepoint == 65) ++count_a;
        else if (codepoint == 67) ++count_c;
        else if (codepoint == 71) ++count_g;
        else if (codepoint == 84) ++count_t;
    }
    const size_t output_length = decimal_length(count_a) + decimal_length(count_c) +
        decimal_length(count_g) + decimal_length(count_t) + 3;
    if (output == NULL || capacity < output_length) return -2;
    size_t offset = write_decimal(output, 0, count_a); output[offset++] = ' ';
    offset = write_decimal(output, offset, count_c); output[offset++] = ' ';
    offset = write_decimal(output, offset, count_g); output[offset++] = ' ';
    offset = write_decimal(output, offset, count_t);
    return (int64_t)offset;
}
