// Squareplus activation for one element of the source vector.
#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double squareplus(double x, double beta) noexcept {
    if (!(std::isfinite(x) && std::isfinite(beta) && x >= -10000.0 && x <= 10000.0 && beta >= 0.25 && beta <= 10000.0)) return INVALID_RESULT;
    return (x + std::sqrt(x * x + beta)) / 2.0;
}
