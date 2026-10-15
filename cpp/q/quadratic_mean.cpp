// Quadratic mean, also known as root mean square.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 64; }

extern "C" double quadratic_mean(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > max_length) return -1.0e300;
    double square_sum = 0.0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = values[index];
        if (value < -1000 || value > 1000) return -1.0e300;
        const double converted = static_cast<double>(value);
        square_sum += converted * converted;
    }
    return std::sqrt(square_sum / static_cast<double>(length));
}
