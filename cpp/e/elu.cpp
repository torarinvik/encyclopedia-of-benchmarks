// Conventional exponential linear unit from the pinned MATLAB formula.
#include <cmath>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double ALPHA_MAX = 1'000'000.0;
}

extern "C" double elu(double x, double alpha) noexcept {
    if (!std::isfinite(x) || !std::isfinite(alpha) || x < -100.0 || x > 100.0 ||
        alpha < -ALPHA_MAX || alpha > ALPHA_MAX) return INVALID_RESULT;
    return x < 0.0 ? alpha * (std::exp(x) - 1.0) : x;
}
