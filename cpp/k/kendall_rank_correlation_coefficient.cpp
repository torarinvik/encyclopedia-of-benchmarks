#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double invalid_result = -1.0e300; }

extern "C" double kendall_rank_correlation_coefficient(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length < 5 || length > 257) return invalid_result;
    const auto count = values[0];
    if (count < 2 || count > 128 || length != 1 + 2 * static_cast<std::size_t>(count)) return invalid_result;
    for (std::size_t i = 0; i < 2 * static_cast<std::size_t>(count); ++i)
        if (values[1 + i] < -1'000'000 || values[1 + i] > 1'000'000) return invalid_result;

    std::int64_t concordant = 0, discordant = 0, ties_x = 0, ties_y = 0;
    const auto n = static_cast<std::size_t>(count);
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = i + 1; j < n; ++j) {
            const auto x1 = values[1 + i], x2 = values[1 + j];
            const auto y1 = values[1 + n + i], y2 = values[1 + n + j];
            if (x1 == x2) ++ties_x;
            if (y1 == y2) ++ties_y;
            if ((x1 < x2 && y1 < y2) || (x1 > x2 && y1 > y2)) ++concordant;
            else if ((x1 < x2 && y1 > y2) || (x1 > x2 && y1 < y2)) ++discordant;
        }
    }
    const double pairs = static_cast<double>(n * (n - 1) / 2);
    const double denominator = std::sqrt((pairs - static_cast<double>(ties_x)) * (pairs - static_cast<double>(ties_y)));
    if (denominator == 0.0) return invalid_result;
    return static_cast<double>(concordant - discordant) / denominator;
}
