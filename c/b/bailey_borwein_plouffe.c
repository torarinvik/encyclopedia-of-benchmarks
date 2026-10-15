/* Return the source's extracted hexadecimal digit as a numeric nibble. */
#include <math.h>
#include <stdint.h>

static int64_t modular_power_16(int64_t exponent, int64_t modulus)
{
    int64_t result = 1 % modulus;
    int64_t base = 16 % modulus;
    while (exponent > 0) {
        if (exponent & 1) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static double bbp_subsum(int64_t position, int64_t addend)
{
    double total = 0.0;
    for (int64_t index = 0; index < position + 1000; ++index) {
        const int64_t denominator = 8 * index + addend;
        const int64_t exponent = position - 1 - index;
        const double term = index < position
            ? (double)modular_power_16(exponent, denominator) / (double)denominator
            : pow(16.0, (double)exponent) / (double)denominator;
        total += term;
    }
    return total;
}

int64_t bailey_borwein_plouffe(int64_t digit_position)
{
    if (digit_position < 1 || digit_position > 10) return -1;
    const double sum_result = 4.0 * bbp_subsum(digit_position, 1)
        - 2.0 * bbp_subsum(digit_position, 4)
        - bbp_subsum(digit_position, 5)
        - bbp_subsum(digit_position, 6);
    const double fractional = sum_result - floor(sum_result);
    return (int64_t)(fractional * 16.0);
}
