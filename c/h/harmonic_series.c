/* Emit the source's harmonic-series string list as newline-delimited ASCII. */
#include <stddef.h>
#include <stdint.h>

static size_t append_decimal(uint8_t *out, size_t position, size_t value) {
    uint8_t digits[4];
    size_t count = 0;
    do { digits[count++] = (uint8_t)(value % 10); value /= 10; } while (value != 0);
    while (count > 0) out[position++] = (uint8_t)('0' + digits[--count]);
    return position;
}

int64_t harmonic_series(int64_t n, uint8_t *output, size_t capacity) {
    if (n < -512 || n > 512) return -1;
    if (n <= 0) return 0;
    size_t needed = 2;
    for (size_t term = 2; term <= (size_t)n; ++term) {
        size_t value = term, digits = 0;
        do { ++digits; value /= 10; } while (value != 0);
        needed += digits + 3;
    }
    if (output == NULL || capacity < needed) return -2;
    size_t position = 0;
    output[position++] = '1'; output[position++] = '\n';
    for (size_t term = 2; term <= (size_t)n; ++term) {
        output[position++] = '1'; output[position++] = '/';
        position = append_decimal(output, position, term);
        output[position++] = '\n';
    }
    return (int64_t)position;
}
