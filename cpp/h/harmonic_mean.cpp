// Harmonic mean of positive values.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 64; }

extern "C" double harmonic_mean(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > max_length) return -1.0e300;
    double reciprocal_sum = 0.0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = values[index];
        if (value < 1 || value > 1000) return -1.0e300;
        reciprocal_sum += 1.0 / static_cast<double>(value);
    }
    return static_cast<double>(length) / reciprocal_sum;
}
