#include <math.h>

double liters_to_imperial_gallons(double liters)
{
    if (!isfinite(liters) || liters < -1e100 || liters > 1e100) return -1e300;
    return liters / 4.54609;
}
