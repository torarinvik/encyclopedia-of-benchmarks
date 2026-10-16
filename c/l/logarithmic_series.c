/* Emit the pinned default logarithmic-series expressions as ASCII lines. */
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

static int has_negative_sign(int64_t delta, int64_t term)
{
    return delta < 0 ? term % 2 == 1 : term % 2 == 0;
}

int64_t logarithmic_series(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != 2) return -1;
    const int64_t x_value = values[0], n_terms = values[1];
    if (x_value < -10 || x_value > 10 || n_terms < -64 || n_terms > 256) return -1;
    if (n_terms <= 0) return 0;
    const int64_t delta = x_value - 1;
    const uint64_t base = delta < 0 ? (uint64_t)(-delta) : (uint64_t)delta;
    size_t needed = 0;
    for (int64_t term = 1; term <= n_terms; ++term) {
        needed += (has_negative_sign(delta, term) ? 2 : 1) + decimal_width(base)
                  + 2 * decimal_width((uint64_t)term) + 4;
    }
    if (output == NULL || output_capacity < needed) return -2;

    size_t position = 0;
    for (int64_t term = 1; term <= n_terms; ++term) {
        if (has_negative_sign(delta, term)) output[position++] = '-';
        output[position++] = '(';
        position = append_decimal(output, position, base);
        output[position++] = '^';
        position = append_decimal(output, position, (uint64_t)term);
        output[position++] = ')'; output[position++] = '/';
        position = append_decimal(output, position, (uint64_t)term);
        output[position++] = '\n';
    }
    return (int64_t)position;
}
