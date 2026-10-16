/* Emit the bounded Python P-series list as newline-delimited ASCII. */
#include <stddef.h>
#include <stdint.h>

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

static uint64_t term_power(size_t term, int64_t power)
{
    uint64_t result = 1;
    for (int64_t index = 0; index < power; ++index) result *= (uint64_t)term;
    return result;
}

int64_t p_series(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 2) return -1;
    const int64_t nth_term = values[0];
    const int64_t power = values[1];
    if (nth_term < -256 || nth_term > 256 || power < 0 || power > 7) return -1;
    if (nth_term <= 0) return 0;

    size_t needed = 2;
    for (size_t term = 2; term <= (size_t)nth_term; ++term)
        needed += 5 + decimal_width(term_power(term, power));
    if (output == NULL || output_capacity < needed) return -2;

    size_t position = 0;
    output[position++] = '1'; output[position++] = '\n';
    for (size_t term = 2; term <= (size_t)nth_term; ++term) {
        output[position++] = '1'; output[position++] = ' ';
        output[position++] = '/'; output[position++] = ' ';
        position = append_decimal(output, position, term_power(term, power));
        output[position++] = '\n';
    }
    return (int64_t)position;
}
