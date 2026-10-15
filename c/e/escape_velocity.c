/* Escape velocity with the source's three-decimal result rounding. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double round_three_even(double value)
{
    const double scaled = value * 1000.0;
    const double lower = floor(scaled);
    const double midpoint = lower + 0.5;
    const double exact_side = fma(value, 1000.0, -midpoint);
    int64_t rounded = (int64_t)lower;
    if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) ++rounded;
    return (double)rounded / 1000.0;
}

double escape_velocity(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t mass = values[0], radius = values[1];
    if (mass < 0 || mass > INT64_C(1000000000000000) || radius < 1 || radius > INT64_C(1000000000)) return INVALID_RESULT;
    const double velocity = sqrt(2.0 * 6.67430e-11 * (double)mass / (double)radius);
    return round_three_even(velocity);
}
