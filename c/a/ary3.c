#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static size_t decimal_digits(uint32_t value)
{
    size_t count = 1;
    while (value >= 10) {
        value /= 10;
        ++count;
    }
    return count;
}

static size_t write_decimal(uint32_t value, uint8_t *output)
{
    uint8_t reversed[10];
    size_t count = 0;
    do {
        reversed[count++] = (uint8_t)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    for (size_t index = 0; index < count; ++index)
        output[index] = reversed[count - index - 1];
    return count;
}

int64_t ary3(int64_t length, uint8_t *output, size_t output_capacity)
{
    if (length < 1 || length > MAX_LENGTH) return -1;
    const size_t n = (size_t)length;
    int32_t x[MAX_LENGTH];
    int32_t y[MAX_LENGTH];

    for (size_t index = 0; index < n; ++index) {
        x[index] = (int32_t)(index + 1);
        y[index] = 0;
    }
    for (size_t pass = 0; pass < 1000; ++pass) {
        for (size_t index = n; index > 0; --index) {
            const size_t position = index - 1;
            y[position] += x[position];
        }
    }

    const uint32_t first = (uint32_t)y[0];
    const uint32_t last = (uint32_t)y[n - 1];
    const size_t first_digits = decimal_digits(first);
    const size_t last_digits = decimal_digits(last);
    const size_t required = first_digits + 2 + last_digits;
    if (output == NULL || output_capacity < required) return -2;
    write_decimal(first, output);
    output[first_digits] = (uint8_t)' ';
    write_decimal(last, output + first_digits + 1);
    output[required - 1] = (uint8_t)'\n';
    return (int64_t)required;
}
