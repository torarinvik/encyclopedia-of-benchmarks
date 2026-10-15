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

int64_t euler_totient_sequence(int64_t n, uint8_t *output, size_t output_capacity)
{
    if (n < 1 || n > 80) return -1;
    int64_t phi[81] = {0};
    for (int64_t value = 1; value <= n; ++value) {
        int64_t remaining = value;
        int64_t totient = value;
        for (int64_t p = 2; p * p <= remaining; ++p) {
            if (remaining % p != 0) continue;
            do { remaining /= p; } while (remaining % p == 0);
            totient -= totient / p;
        }
        if (remaining > 1) totient -= totient / remaining;
        phi[value] = totient;
    }
    size_t required = (size_t)(n - 1);
    for (int64_t i = 1; i <= n; ++i) required += decimal_length(phi[i]);
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    for (int64_t i = 1; i <= n; ++i) {
        if (i != 1) output[position++] = ',';
        position = append_decimal(phi[i], output, position);
    }
    return (int64_t)position;
}
