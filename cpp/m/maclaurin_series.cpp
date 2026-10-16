#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; constexpr double pi = 3.14159265358979323846264338327950288;
double factorial(std::int64_t n) { double result = 1.0; for (std::int64_t i = 2; i <= n; ++i) result *= static_cast<double>(i); return result; } }

extern "C" double maclaurin_series(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return invalid_result;
    const std::int64_t mode = values[0], theta_input = values[1], accuracy = values[2];
    if ((mode != 0 && mode != 1) || theta_input < -10 || theta_input > 10 || accuracy < 1 || accuracy > 30) return invalid_result;
    double theta = static_cast<double>(theta_input);
    const double div = std::floor(theta / (2.0 * pi));
    theta = theta - 2.0 * div * pi;
    double sum = 0.0;
    for (std::int64_t r = 0; r < accuracy; ++r) {
        const std::int64_t exponent = mode == 0 ? 2 * r + 1 : 2 * r;
        const double sign = (r % 2 == 0) ? 1.0 : -1.0;
        sum += sign * std::pow(theta, static_cast<double>(exponent)) / factorial(exponent);
    }
    return sum;
}
