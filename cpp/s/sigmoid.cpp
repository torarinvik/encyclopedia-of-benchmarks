#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double sigmoid(double x) noexcept
{
    if (std::isnan(x) || x < -20.0 || x > 20.0) return INVALID_RESULT;
    return 1.0 / (1.0 + std::exp(-x));
}
