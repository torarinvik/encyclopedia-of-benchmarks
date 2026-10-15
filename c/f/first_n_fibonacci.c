/* Emit the first n Fibonacci terms as decimal NUL-terminated values. */
#include <stddef.h>
#include <stdint.h>

#define MIN_COUNT INT64_C(3)
#define MAX_COUNT INT64_C(79)

static size_t decimal_length(int64_t number)
{
    size_t length = 1;
    while (number >= 10) { number /= 10; ++length; }
    return length;
}

static size_t required_length(int64_t count)
{
    size_t bytes = 0;
    int64_t previous = 0, current = 1;
    for (int64_t index = 0; index < count; ++index) {
        int64_t value;
        if (index == 0) value = 0;
        else if (index == 1) value = 1;
        else { value = previous + current; previous = current; current = value; }
        bytes += decimal_length(value) + 1;
    }
    return bytes;
}

static size_t append_decimal(int64_t number, uint8_t *output, size_t position)
{
    uint8_t digits[20];
    size_t count = 0;
    do { digits[count++] = (uint8_t)('0' + number % 10); number /= 10; } while (number > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

int64_t first_n_fibonacci(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 1) return -1;
    const int64_t count = values[0];
    if (count < MIN_COUNT || count > MAX_COUNT) return -1;
    const size_t required = required_length(count);
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    int64_t previous = 0, current = 1;
    for (int64_t index = 0; index < count; ++index) {
        int64_t value;
        if (index == 0) value = 0;
        else if (index == 1) value = 1;
        else { value = previous + current; previous = current; current = value; }
        position = append_decimal(value, output, position);
        output[position++] = 0;
    }
    return (int64_t)position;
}
