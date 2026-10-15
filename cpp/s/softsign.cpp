#include <cmath>

namespace { constexpr double invalid_result = -1.0e300; }

extern "C" double softsign(double x) noexcept
{
    if (std::isnan(x) || x < -1.0e100 || x > 1.0e100) return invalid_result;
    return x / (1.0 + std::abs(x));
}
