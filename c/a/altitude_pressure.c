/* Estimate altitude from pressure using the pinned source formula. */
#include <math.h>

double altitude_pressure(double pressure)
{
    if (pressure < 0.0 || pressure > 101325.0) return -1.0;
    if (pressure == 0.0) return 44330.0;
    const double exponent = 1.0 / 5.5255;
    return 44330.0 * (1.0 - pow(pressure / 101325.0, exponent));
}
