/* Bragg diffraction angle, rounded to one decimal degree. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define PI 3.141592653589793238462643383279502884

static double round_one_even(double value)
{
    const double scaled = value * 10.0;
    const double lower = floor(scaled);
    const double fraction = scaled - lower;
    int64_t rounded = (int64_t)lower;
    if (fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0)) ++rounded;
    return (double)rounded / 10.0;
}

double bragg_angle(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t distance = values[0], order = values[1], wavelength = values[2];
    if (distance < 1 || distance > 1000000 || order < -1000 || order > 1000 || wavelength < 0 || wavelength > 1000000)
        return INVALID_RESULT;
    const double sine = ((double)order * (double)wavelength) / (2.0 * (double)distance);
    if (sine < -1.0 || sine > 1.0) return INVALID_RESULT;
    const double degrees = asin(sine) * (180.0 / PI);
    return round_one_even(degrees);
}
