// Estimate altitude from pressure using the pinned source formula.
#include <cmath>

extern "C" double altitude_pressure(double pressure) noexcept
{
    if (pressure < 0.0 || pressure > 101325.0) return -1.0;
    if (pressure == 0.0) return 44330.0;
    const double exponent = 1.0 / 5.5255;
    return 44330.0 * (1.0 - std::pow(pressure / 101325.0, exponent));
}
