/* Encode each base-b Harshad string below a limit with a trailing NUL byte. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LIMIT INT64_C(10000)

static int64_t digit_sum(int64_t number, int64_t base)
{
    int64_t sum = 0;
    while (number > 0) {
        sum += number % base;
        number /= base;
    }
    return sum;
}

static size_t base_length(int64_t number, int64_t base)
{
    size_t length = 0;
    do { number /= base; ++length; } while (number > 0);
    return length;
}

static size_t required_length(int64_t limit, int64_t base)
{
    size_t length = 0;
    for (int64_t number = 1; number < limit; ++number) {
        if (number % digit_sum(number, base) != 0) continue;
        length += base_length(number, base) + 1;
    }
    return length;
}

static uint8_t digit_byte(int64_t digit)
{
    return (uint8_t)(digit < 10 ? '0' + digit : 'A' + digit - 10);
}

static size_t append_base(int64_t number, int64_t base, uint8_t *output, size_t position)
{
    uint8_t digits[64];
    size_t count = 0;
    do { digits[count++] = digit_byte(number % base); number /= base; } while (number > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

int64_t harshad_numbers_in_base(const int64_t *values, size_t length,
                                uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 2) return -1;
    const int64_t limit = values[0], base = values[1];
    if (limit > MAX_LIMIT || base < 2 || base > 36) return -1;
    const size_t required = required_length(limit, base);
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    for (int64_t number = 1; number < limit; ++number) {
        if (number % digit_sum(number, base) != 0) continue;
        position = append_base(number, base, output, position);
        output[position++] = 0;
    }
    return (int64_t)position;
}
