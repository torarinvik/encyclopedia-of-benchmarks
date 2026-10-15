// Mish activation for one element of the source vector.
#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double mish(double x) noexcept {
    if (!std::isfinite(x) || x < -20.0 || x > 20.0) return INVALID_RESULT;
    const double softplus = std::log(1.0 + std::exp(x));
    return x * std::tanh(softplus);
}
