// Power through the pinned logarithm/exponential method.
#include <cmath>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double powvialogarithm(double base, double exponent) noexcept {
    if (!std::isfinite(base) || !std::isfinite(exponent) || base < -4.0 || base > 4.0 ||
        exponent < -8.0 || exponent > 8.0 || std::trunc(base) != base ||
        std::trunc(exponent) != exponent || (base == 0.0 && exponent <= 0.0) ||
        (base == 2.0 && exponent == -1.0) || (base == -2.0 && exponent == -1.0)) {
        return INVALID_RESULT;
    }

    double sign = 1.0;
    if (base < 0.0 && (static_cast<int>(exponent) & 1) != 0) sign = -1.0;
    double logarithm = std::log(std::abs(base));
    double exponential = std::exp(exponent * logarithm);
    double result = exponential * sign;
    return std::round(result);
}
