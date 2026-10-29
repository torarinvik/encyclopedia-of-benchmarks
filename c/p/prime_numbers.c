/* Encode all primes through an inclusive limit as comma-separated decimal bytes. */
#include <stddef.h>
#include <stdint.h>

static int is_prime(int64_t value)
{
    if (value < 2) return 0;
    int64_t divisor = 2;
    int64_t quotient = value / divisor;
    while (divisor <= quotient) {
        if (value - quotient * divisor == 0) return 0;
        ++divisor;
        quotient = value / divisor;
    }
    return 1;
}

static size_t decimal_length(int64_t value)
{
    size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
    return length;
}

static size_t required_length(int64_t limit)
{
    size_t length = 0, count = 0;
    for (int64_t value = 2; value <= limit; ++value) {
        if (!is_prime(value)) continue;
        length += decimal_length(value) + (count != 0);
        ++count;
    }
    return length;
}

static size_t append_decimal(int64_t value, uint8_t *output, size_t position)
{
    uint8_t digits[3];
    size_t count = 0;
    do { digits[count++] = (uint8_t)(value % 10); value /= 10; } while (value > 0);
    while (count > 0) output[position++] = (uint8_t)('0' + digits[--count]);
    return position;
}

int64_t prime_numbers(int64_t limit, uint8_t *output, size_t output_capacity)
{
    if (limit < 0 || limit > 80) return -1;
    const size_t required = required_length(limit);
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0, count = 0;
    for (int64_t value = 2; value <= limit; ++value) {
        if (!is_prime(value)) continue;
        if (count != 0) output[position++] = ',';
        position = append_decimal(value, output, position);
        ++count;
    }
    return (int64_t)position;
}
