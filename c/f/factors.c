/* List all positive divisors in ascending decimal order. */
#include <stddef.h>
#include <stdint.h>

static size_t decimal_length(int64_t value)
{
    size_t length = 1;
    while (value >= 10) {
        value /= 10;
        ++length;
    }
    return length;
}

static size_t append_decimal(int64_t value, uint8_t *output, size_t position)
{
    uint8_t digits[3];
    size_t count = 0;
    do {
        digits[count++] = (uint8_t)(value % 10);
        value /= 10;
    } while (value > 0);
    while (count > 0) {
        output[position++] = (uint8_t)('0' + digits[--count]);
    }
    return position;
}

int64_t factors(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value < 1 || value > 256) return -1;
    size_t required = 0;
    size_t count = 0;
    for (int64_t divisor = 1; divisor <= value; ++divisor) {
        if (value % divisor == 0) {
            required += decimal_length(divisor) + (count != 0);
            ++count;
        }
    }
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    count = 0;
    for (int64_t divisor = 1; divisor <= value; ++divisor) {
        if (value % divisor == 0) {
            if (count != 0) output[position++] = ',';
            position = append_decimal(divisor, output, position);
            ++count;
        }
    }
    return (int64_t)position;
}
