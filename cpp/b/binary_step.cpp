// Binary step over a bounded finite binary64 domain.
#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double binary_step(double x) noexcept {
    if (!std::isfinite(x) || x < -1'000'000.0 || x > 1'000'000.0) return INVALID_RESULT;
    return x >= 0.0 ? 1.0 : 0.0;
}
