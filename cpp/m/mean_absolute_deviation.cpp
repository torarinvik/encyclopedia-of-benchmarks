// Mean absolute deviation from the arithmetic mean.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 256; }

extern "C" double mean_absolute_deviation(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_length + 1) return -1.0e300;
    const auto count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_length) ||
        length != static_cast<std::size_t>(count_value) + 1) return -1.0e300;
    const auto count = static_cast<std::size_t>(count_value);
    double sum = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = values[index + 1];
        if (value < -1000000 || value > 1000000) return -1.0e300;
        sum += static_cast<double>(value);
    }
    const double mean = sum / static_cast<double>(count);
    double absolute_sum = 0.0;
    for (std::size_t index = 0; index < count; ++index)
        absolute_sum += std::fabs(static_cast<double>(values[index + 1]) - mean);
    return absolute_sum / static_cast<double>(count);
}
