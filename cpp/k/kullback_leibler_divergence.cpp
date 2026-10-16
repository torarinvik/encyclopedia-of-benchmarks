#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_COUNT = 64;
constexpr double SCALE = 1000000.0;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double kullback_leibler_divergence(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > 129) return INVALID_RESULT;
    const std::int64_t count_value = values[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(MAX_COUNT)) return INVALID_RESULT;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return INVALID_RESULT;

    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t target = values[1 + i];
        const std::int64_t prediction = values[1 + count + i];
        if (target < 0 || target > 1000000 || prediction < 0 || prediction > 1000000 ||
            (target > 0 && prediction == 0)) {
            return INVALID_RESULT;
        }
    }
    double total = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t target_scaled = values[1 + i];
        if (target_scaled == 0) continue;
        const std::int64_t prediction_scaled = values[1 + count + i];
        const double target = static_cast<double>(target_scaled) / SCALE;
        const double prediction = static_cast<double>(prediction_scaled) / SCALE;
        total += target * std::log(target / prediction);
    }
    return total;
}
