// Pinned Python GELU approximation: x * (1 / (1 + exp(-1.702*x))).
#include <cmath>

extern "C" double gaussian_error_linear_unit(double x) noexcept {
    if (!std::isfinite(x) || x < -100.0 || x > 100.0) return -1.0e300;
    return x * (1.0 / (1.0 + std::exp(-1.702 * x)));
}
