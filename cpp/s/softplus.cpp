#include <cmath>

namespace { constexpr double invalid_result = -1.0e300; }

extern "C" double softplus(double x) noexcept
{
    if (std::isnan(x) || x < -100.0 || x > 100.0) return invalid_result;
    return std::log(1.0 + std::exp(x));
}
