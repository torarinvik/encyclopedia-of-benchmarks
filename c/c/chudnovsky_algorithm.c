#include <stddef.h>
#include <stdint.h>

#define MAX_PRECISION 12

static double sqrt_10005(void)
{
    double root = 100.0;
    for (int iteration = 0; iteration < 8; ++iteration)
        root = 0.5 * (root + 10005.0 / root);
    return root;
}

int64_t chudnovsky_algorithm(const int64_t *values, size_t length,
                             uint8_t *output, size_t capacity)
{
    if (values == NULL || length != 1 || values[0] < 1 || values[0] > MAX_PRECISION) return -1;
    const size_t precision = (size_t)values[0];
    const size_t output_length = precision == 1 ? 0 : precision;
    if (capacity < output_length || (output_length > 0 && output == NULL)) return -2;
    if (precision == 1) return 0;

    const double pi = (426880.0 * sqrt_10005()) / 13591409.0;
    double fraction = pi - 3.0;
    output[0] = '3';
    output[1] = '.';
    for (size_t digit = 0; digit < precision - 2; ++digit) {
        fraction *= 10.0;
        const int next_digit = (int)fraction;
        output[2 + digit] = (uint8_t)('0' + next_digit);
        fraction -= (double)next_digit;
    }
    return (int64_t)output_length;
}
