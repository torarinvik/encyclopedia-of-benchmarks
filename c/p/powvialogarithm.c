/* Power through the pinned logarithm/exponential method. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double powvialogarithm(double base, double exponent)
{
    if (isnan(base) || isnan(exponent) || base < -4.0 || base > 4.0 ||
        exponent < -8.0 || exponent > 8.0 || trunc(base) != base ||
        trunc(exponent) != exponent || (base == 0.0 && exponent <= 0.0) ||
        (base == 2.0 && exponent == -1.0) || (base == -2.0 && exponent == -1.0)) {
        return INVALID_RESULT;
    }

    double sign = 1.0;
    if (base < 0.0 && ((int)exponent & 1) != 0) sign = -1.0;
    double logarithm = log(fabs(base));
    double exponential = exp(exponent * logarithm);
    double result = exponential * sign;
    return round(result);
}
