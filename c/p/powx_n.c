#include <stdint.h>

static double pow_positive(double base, int64_t exponent)
{
    if (exponent == 0) return 1.0;
    int64_t mask = 1;
    while (mask <= exponent / 2) mask <<= 1;
    double result = base;
    mask >>= 1;
    while (mask != 0) {
        result *= result;
        if ((exponent & mask) != 0) result *= base;
        mask >>= 1;
    }
    return result;
}

double powx_n(double base, int32_t exponent)
{
    if (exponent == 0) return 1.0;
    if (exponent == INT32_MIN)
        return 1.0 / (pow_positive(base, INT32_MAX) * base);
    if (exponent < 0) return 1.0 / pow_positive(base, -(int64_t)exponent);
    return pow_positive(base, exponent);
}
