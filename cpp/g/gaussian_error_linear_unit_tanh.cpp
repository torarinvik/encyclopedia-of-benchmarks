// Pinned Rust GELU approximation with its exponential tanh identity.
#include <cmath>

namespace {
constexpr double pi_value = 3.14159265358979323846264338327950288;
constexpr double e_value = 2.71828182845904523536028747135266250;
}

extern "C" double gaussian_error_linear_unit_tanh(double x) noexcept {
    if (!std::isfinite(x) || x < -100.0 || x > 100.0) return -1.0e300;
    const double scale = std::pow(2.0 / pi_value, 0.5);
    const double z = scale * (x + 0.044715 * std::pow(x, 3.0));
    const double tanh_value = 2.0 / (1.0 + std::pow(e_value, -2.0 * z)) - 1.0;
    return x * 0.5 * (1.0 + tanh_value);
}
