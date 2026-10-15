// Small-amplitude pendulum period: 2 * pi * sqrt(length / g).
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double PI = 3.141592653589793238462643383279502884; }

extern "C" double period_of_pendulum(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 1) return -1.0e300;
    const std::int64_t pendulum_length = values[0];
    if (pendulum_length < 0 || pendulum_length > 1000) return -1.0e300;
    const double root = std::pow(static_cast<double>(pendulum_length) / 9.80665, 0.5);
    return (2.0 * PI) * root;
}
