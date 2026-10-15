/* Encode phi(1) through phi(n) as comma-separated decimal bytes. */
#include <stddef.h>
#include <stdint.h>

static size_t decimal_length(int64_t value)
{
    size_t length = 1;
    while (value >= 10) { value /= 10; ++length; }
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

int64_t compute_totient(int64_t n, uint8_t *output, size_t output_capacity)
{
    if (n < 1 || n > 80) return -1;
    int64_t phi[80];
    for (int64_t i = 1; i <= n; ++i) phi[i - 1] = i;
    for (int64_t p = 2; p <= n; ++p) {
        if (phi[p - 1] != p) continue;
        phi[p - 1] = p - 1;
        for (int64_t i = 2 * p; i <= n; i += p)
            phi[i - 1] = (phi[i - 1] / p) * (p - 1);
    }
    size_t required = (size_t)(n - 1);
    for (int64_t i = 0; i < n; ++i) required += decimal_length(phi[i]);
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    for (int64_t i = 0; i < n; ++i) {
        if (i != 0) output[position++] = ',';
        position = append_decimal(phi[i], output, position);
    }
    return (int64_t)position;
}
