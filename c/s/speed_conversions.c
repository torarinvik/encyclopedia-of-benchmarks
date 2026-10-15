/* Convert a bounded speed between four source-defined units. */
#include <math.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0)

static double round_three_even(double value)
{
    const double lower = floor(value * 1000.0);
    const double midpoint = lower + 0.5;
    const double exact_side = fma(value, 1000.0, -midpoint);
    int64_t rounded = (int64_t)lower;
    if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) ++rounded;
    return (double)rounded / 1000.0;
}

double speed_conversions(double speed, double route)
{
    if (!isfinite(speed) || !isfinite(route) || speed < 0.0 || speed > 1000000.0 ||
        route < 0.0 || route > 15.0 || floor(route) != route) return INVALID_RESULT;
    static const double factors[4] = {1.0, 3.6, 1.609344, 1.852};
    static const double inverse_factors[4] = {1.0, 0.277777778, 0.621371192, 0.539956803};
    const int unit_from = (int)route / 4;
    const int unit_to = (int)route % 4;
    return round_three_even(speed * factors[unit_from] * inverse_factors[unit_to]);
}
