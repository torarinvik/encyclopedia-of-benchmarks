#include <cmath>

extern "C" double liters_to_usgallons(double liters) noexcept
{
    if (!std::isfinite(liters) || liters < -1e100 || liters > 1e100) return -1e300;
    return liters / 3.785411784;
}
