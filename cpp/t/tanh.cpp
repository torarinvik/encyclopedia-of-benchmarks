// Hyperbolic tangent using the normalized logistic identity.
#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double tanh(double x) noexcept {
    if (!std::isfinite(x) || x < -10.0 || x > 10.0) return INVALID_RESULT;
    return (2.0 / (1.0 + std::exp(-2.0 * x))) - 1.0;
}
