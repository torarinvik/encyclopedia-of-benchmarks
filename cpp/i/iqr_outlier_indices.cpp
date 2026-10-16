#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 62; constexpr std::int64_t invalid_result = -1; }

static double type7_quantile(const std::int64_t *sorted, std::size_t count, double probability) {
    const double h = static_cast<double>(count - 1) * probability + 1.0;
    const auto order = static_cast<std::size_t>(h);
    const double fraction = h - static_cast<double>(order);
    const auto lower = order - 1;
    if (fraction == 0.0 || lower + 1 >= count) return static_cast<double>(sorted[lower]);
    return (1.0 - fraction) * static_cast<double>(sorted[lower])
         + fraction * static_cast<double>(sorted[lower + 1]);
}

extern "C" std::int64_t iqr_outlier_indices(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length == 0 || length > max_length) return invalid_result;
    std::int64_t sorted[max_length];
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < -1'000'000 || values[i] > 1'000'000) return invalid_result;
        std::size_t j = i;
        while (j > 0 && sorted[j - 1] > values[i]) { sorted[j] = sorted[j - 1]; --j; }
        sorted[j] = values[i];
    }
    const double q1 = type7_quantile(sorted, length, 0.25);
    const double q3 = type7_quantile(sorted, length, 0.75);
    const double iqr = q3 - q1;
    const double lower_bound = q1 - 1.5 * iqr;
    const double upper_bound = q3 + 1.5 * iqr;
    std::int64_t mask = 0;
    for (std::size_t i = 0; i < length; ++i)
        if (static_cast<double>(values[i]) < lower_bound || static_cast<double>(values[i]) > upper_bound) mask |= INT64_C(1) << i;
    return mask;
}
