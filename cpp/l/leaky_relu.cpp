// Leaky ReLU for one vector element and a caller-supplied slope.
#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; constexpr double MAX_INPUT = 1'000'000.0; }

extern "C" double leaky_relu(double x, double alpha) noexcept {
    if (!std::isfinite(x) || !std::isfinite(alpha) || x < -MAX_INPUT || x > MAX_INPUT ||
        alpha < -MAX_INPUT || alpha > MAX_INPUT) return INVALID_RESULT;
    return x < 0.0 ? x * alpha : x;
}
