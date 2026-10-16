/* Convert a bounded speed between five source-defined units. */
#include <math.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0)

static double round_two_php(double value)
{
    return floor(value * 100.0 + 0.5) / 100.0;
}

double speed_conversion(double speed, double route)
{
    if (!isfinite(speed) || !isfinite(route) || speed < 0.0 || speed > 1000000.0 ||
        route < 0.0 || route > 24.0 || floor(route) != route) return INVALID_RESULT;
    static const double factors[5] = {1.609344, 1.0, 3.6, 1.097, 1.852};
    static const double inverse_factors[5] = {0.6213712, 1.0, 0.277778, 0.911344, 0.539957};
    const int unit_from = (int)route / 5;
    const int unit_to = (int)route % 5;
    return round_two_php(speed * factors[unit_from] * inverse_factors[unit_to]);
}
