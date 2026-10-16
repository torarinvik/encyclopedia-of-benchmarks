#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; constexpr double pi = 3.14159265358979323846264338327950288; }

extern "C" double gaussian(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return invalid_result;
    const std::int64_t x = values[0], mu = values[1], sigma = values[2];
    if (x < -100 || x > 100 || mu < -100 || mu > 100 || sigma < 1 || sigma > 100) return invalid_result;
    const std::int64_t difference = x - mu;
    const std::int64_t sigma_squared = sigma * sigma;
    const double normalization = 1.0 / std::sqrt(2.0 * pi * static_cast<double>(sigma_squared));
    const double exponent = -static_cast<double>(difference * difference) / static_cast<double>(2 * sigma_squared);
    return normalization * std::exp(exponent);
}
