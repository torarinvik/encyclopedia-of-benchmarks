#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; }

static double average_rank(const std::int64_t *samples, std::size_t count, std::size_t index) {
    std::int64_t less = 0, equal = 0;
    for (std::size_t j = 0; j < count; ++j) {
        if (samples[j] < samples[index]) ++less;
        if (samples[j] == samples[index]) ++equal;
    }
    return static_cast<double>(less) + (static_cast<double>(equal) + 1.0) / 2.0;
}

extern "C" double spearman_average_rank_correlation(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length < 5 || length > 257) return invalid_result;
    const auto count = values[0];
    if (count < 2 || count > 128 || length != 1 + 2 * static_cast<std::size_t>(count)) return invalid_result;
    const auto n = static_cast<std::size_t>(count);
    const auto *x_values = values + 1;
    const auto *y_values = values + 1 + n;
    for (std::size_t i = 0; i < 2 * n; ++i)
        if (values[1 + i] < -1'000'000 || values[1 + i] > 1'000'000) return invalid_result;
    const double mean_rank = (static_cast<double>(n) + 1.0) / 2.0;
    double covariance = 0.0, variance_x = 0.0, variance_y = 0.0;
    for (std::size_t i = 0; i < n; ++i) {
        const double dx = average_rank(x_values, n, i) - mean_rank;
        const double dy = average_rank(y_values, n, i) - mean_rank;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x == 0.0 || variance_y == 0.0) return invalid_result;
    return covariance / std::sqrt(variance_x * variance_y);
}
