// Pinned Python Swish expression with trainable_parameter fixed to 1.
#include <cmath>

extern "C" double swish(double x) noexcept {
    if (!std::isfinite(x) || x < -100.0 || x > 100.0) return -1.0e300;
    const double scaled = 1.0 * x;
    return x * (1.0 / (1.0 + std::exp(-scaled)));
}
