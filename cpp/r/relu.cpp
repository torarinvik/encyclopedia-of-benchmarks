// Rectified linear unit over a bounded integer-valued binary64 domain.
#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; constexpr double MAX_INPUT = 16777216.0; }

extern "C" double relu(double x) noexcept {
    if (!std::isfinite(x) || x < -MAX_INPUT || x > MAX_INPUT || std::trunc(x) != x) return INVALID_RESULT;
    return x > 0.0 ? x : 0.0;
}
