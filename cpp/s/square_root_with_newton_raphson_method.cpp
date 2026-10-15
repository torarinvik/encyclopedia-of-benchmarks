// Newton-Raphson square root under the pinned integer input contract.
#include <cmath>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double MAX_INPUT = 2147483647.0;
}

extern "C" double square_root_with_newton_raphson_method(double input) noexcept {
    if (!std::isfinite(input) || input < 1.0 || input > MAX_INPUT || std::trunc(input) != input) {
        return INVALID_RESULT;
    }
    double guess = input;
    double root = 0.5 * (guess + input / guess);
    while (std::fabs(root - guess) > 1e-7) {
        guess = root;
        root = 0.5 * (guess + input / guess);
    }
    return root;
}
