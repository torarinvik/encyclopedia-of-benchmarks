/* Emit reduced proper fractions for one positive denominator. */
#include <stddef.h>
#include <stdint.h>

static uint64_t gcd_u64(uint64_t left, uint64_t right)
{
    while (right != 0) { uint64_t remainder = left % right; left = right; right = remainder; }
    return left;
}

static size_t decimal_width(uint64_t value)
{
    size_t width = 1;
    while (value >= 10) { value /= 10; ++width; }
    return width;
}

static size_t append_decimal(uint8_t *output, size_t position, uint64_t value)
{
    uint8_t digits[20];
    size_t count = 0;
    do { digits[count++] = (uint8_t)(value % 10); value /= 10; } while (value != 0);
    while (count > 0) output[position++] = (uint8_t)('0' + digits[--count]);
    return position;
}

int64_t proper_fractions(const int64_t *values, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 1) return -1;
    const int64_t denominator = values[0];
    if (denominator < 0 || denominator > 256) return -1;
    if (denominator <= 1) return 0;
    size_t needed = 0;
    for (uint64_t numerator = 1; numerator < (uint64_t)denominator; ++numerator)
        if (gcd_u64(numerator, (uint64_t)denominator) == 1)
            needed += decimal_width(numerator) + decimal_width((uint64_t)denominator) + 2;
    if (output == NULL || output_capacity < needed) return -2;
    size_t position = 0;
    for (uint64_t numerator = 1; numerator < (uint64_t)denominator; ++numerator) {
        if (gcd_u64(numerator, (uint64_t)denominator) != 1) continue;
        position = append_decimal(output, position, numerator);
        output[position++] = '/';
        position = append_decimal(output, position, (uint64_t)denominator);
        output[position++] = '\n';
    }
    return (int64_t)position;
}
