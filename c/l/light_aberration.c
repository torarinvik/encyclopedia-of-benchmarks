#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double round_five_even(double value)
{
    const double scaled = value * 100000.0;
    const double fraction = scaled - floor(scaled);
    if (fabs(fraction - 0.5) <= 1.0e-7) return INVALID_RESULT;
    if (value == 0.0) return value;
    const int negative = value < 0.0;
    double normalized = fabs(value);
    int exponent = 0;
    while (normalized < 1.0) { normalized *= 2.0; --exponent; }
    while (normalized >= 2.0) { normalized *= 0.5; ++exponent; }
    const uint64_t mantissa = (uint64_t)(normalized * 4503599627370496.0);
    const int shift = 52 - exponent;
    if (shift > 70) return negative ? -0.0 : 0.0;
    const uint64_t low_product = (mantissa & UINT64_C(0xffffffff)) * UINT64_C(100000);
    const uint64_t high_product = (mantissa >> 32) * UINT64_C(100000);
    const uint64_t shifted_high = high_product << 32;
    const uint64_t low = low_product + shifted_high;
    const uint64_t high = (high_product >> 32) + (low < low_product);
    const uint64_t quotient = shift < 64 ? (low >> shift) | (high << (64 - shift)) : high >> (shift - 64);
    const int half_bit = shift - 1 < 64 ? (int)((low >> (shift - 1)) & 1) : (int)((high >> (shift - 65)) & 1);
    int lower_bits = 0;
    if (shift - 1 < 64) lower_bits = (low & ((UINT64_C(1) << (shift - 1)) - 1)) != 0;
    else lower_bits = low != 0 || (high & ((UINT64_C(1) << (shift - 65)) - 1)) != 0;
    const uint64_t rounded = quotient + (half_bit && (lower_bits || (quotient & 1)));
    const double result = (double)rounded / 100000.0;
    return negative ? -result : result;
}

double light_aberration(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t theta_code = values[0], beta_code = values[1];
    if (theta_code < -3141592 || theta_code > 3141592 || beta_code < 0 || beta_code > 999999) return INVALID_RESULT;
    const double theta = (double)theta_code / 1000000.0;
    const double beta = (double)beta_code / 1000000.0;
    const double factor = sqrt((1.0 - beta) / (1.0 + beta));
    const double angle = 2.0 * atan(factor * tan(theta / 2.0));
    return round_five_even(angle);
}
