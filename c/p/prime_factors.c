/* Encode prime factors in ascending order, retaining multiplicity. */
#include <stddef.h>
#include <stdint.h>

static size_t decimal_length(int64_t value)
{
    size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

static size_t required_length(int64_t value)
{
    size_t length = 0, count = 0;
    int64_t remaining = value;
    for (int64_t divisor = 2; divisor <= remaining / divisor; ++divisor) {
        while (remaining % divisor == 0) {
            length += decimal_length(divisor) + (count != 0);
            ++count;
            remaining /= divisor;
        }
    }
    if (remaining > 1) length += decimal_length(remaining) + (count != 0);
    return length;
}

static size_t append_decimal(int64_t value, uint8_t *output, size_t position)
{
    uint8_t digits[10];
    size_t count = 0;
    do { digits[count++] = (uint8_t)(value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = (uint8_t)('0' + digits[--count]);
    return position;
}

int64_t prime_factors(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 1 || value > 2147483647) return -1;
    const size_t required = required_length(value);
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0, count = 0;
    int64_t remaining = value;
    for (int64_t divisor = 2; divisor <= remaining / divisor; ++divisor) {
        while (remaining % divisor == 0) {
            if (count != 0) output[position++] = ',';
            position = append_decimal(divisor, output, position);
            ++count;
            remaining /= divisor;
        }
    }
    if (remaining > 1) {
        if (count != 0) output[position++] = ',';
        position = append_decimal(remaining, output, position);
    }
    return (int64_t)position;
}
