#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_observations = 128; constexpr std::int64_t max_abs_value = 1'000'000; constexpr double invalid_result = -1.0e300; }

extern "C" double pearson_correlation(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length < 5 || length > 257) return invalid_result;
    const auto count = values[0];
    if (count < 2 || count > static_cast<std::int64_t>(max_observations) || length != 1 + 2 * static_cast<std::size_t>(count)) return invalid_result;

    double sum_x = 0.0, sum_y = 0.0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const auto x = values[1 + i], y = values[1 + static_cast<std::size_t>(count) + i];
        if (x < -max_abs_value || x > max_abs_value || y < -max_abs_value || y > max_abs_value) return invalid_result;
        sum_x += static_cast<double>(x);
        sum_y += static_cast<double>(y);
    }
    const double mean_x = sum_x / static_cast<double>(count), mean_y = sum_y / static_cast<double>(count);
    double covariance = 0.0, variance_x = 0.0, variance_y = 0.0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const double dx = static_cast<double>(values[1 + i]) - mean_x;
        const double dy = static_cast<double>(values[1 + static_cast<std::size_t>(count) + i]) - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x == 0.0 || variance_y == 0.0) return invalid_result;
    return covariance / std::sqrt(variance_x * variance_y);
}
