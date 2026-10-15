/* Enumerate Kaprekar numbers as decimal NUL-terminated values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_END INT64_C(100000)

static int is_kaprekar(int64_t number)
{
    if (number == 0 || number == 1) return 1;
    const int64_t square = number * number;
    int64_t split = 1;
    for (int64_t remaining = number; remaining > 0; remaining /= 10) split *= 10;
    const int64_t right = square % split;
    return right != 0 && square / split + right == number;
}

static size_t decimal_length(int64_t number)
{
    size_t length = 1;
    while (number >= 10) { number /= 10; ++length; }
    return length;
}

static size_t required_length(int64_t start, int64_t end)
{
    size_t bytes = 0;
    for (int64_t number = start; number <= end; ++number)
        if (is_kaprekar(number)) bytes += decimal_length(number) + 1;
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

int64_t kaprekar_numbers_in_range(const int64_t *values, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 2) return -1;
    const int64_t start = values[0], end = values[1];
    if (start < 0 || start > end || end > MAX_END) return -1;
    const size_t required = required_length(start, end);
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    for (int64_t number = start; number <= end; ++number) {
        if (!is_kaprekar(number)) continue;
        position = append_decimal(number, output, position);
        output[position++] = 0;
    }
    return (int64_t)position;
}
