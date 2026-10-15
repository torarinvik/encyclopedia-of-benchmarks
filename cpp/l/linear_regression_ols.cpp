// Univariate ordinary least-squares slope for packed integer observations.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_observations = 128; }

extern "C" double linear_regression_ols(const std::int64_t *values, std::size_t length) noexcept {
    constexpr double invalid_result = -1.0e300;
    if (values == nullptr || length < 5 || length > 1 + 2 * max_observations || length % 2 == 0) return invalid_result;
    const auto count = values[0];
    if (count < 2 || count > static_cast<std::int64_t>(max_observations) || length != 1 + 2 * static_cast<std::size_t>(count)) return invalid_result;

    double sum_x = 0.0;
    double sum_y = 0.0;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        const auto x = values[1 + 2 * index];
        const auto y = values[2 + 2 * index];
        if (x < -1000000 || x > 1000000 || y < -1000000 || y > 1000000) return invalid_result;
        sum_x += static_cast<double>(x);
        sum_y += static_cast<double>(y);
    }
    const double mean_x = sum_x / static_cast<double>(count);
    const double mean_y = sum_y / static_cast<double>(count);
    double covariance = 0.0;
    double variance_x = 0.0;
    double variance_y = 0.0;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        const double dx = static_cast<double>(values[1 + 2 * index]) - mean_x;
        const double dy = static_cast<double>(values[2 + 2 * index]) - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x <= 1e-12 || variance_y <= 1e-12) return invalid_result;
    return covariance / variance_x;
}
