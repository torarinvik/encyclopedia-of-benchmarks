#include <cmath>
#include <cstddef>
#include <cstdint>
namespace {
constexpr std::size_t MAX_LENGTH = 256;
constexpr std::int64_t MIN_VALUE = -2'147'483'648;
constexpr std::int64_t MAX_VALUE = 2'147'483'647;
constexpr double INVALID_RESULT = -1.0e300;
}
extern "C" double average_absolute_deviation_rounded(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double sum = 0.0;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < MIN_VALUE || values[i] > MAX_VALUE) return INVALID_RESULT;
        sum += static_cast<double>(values[i]);
    }
    const double average = sum / static_cast<double>(length);
    double deviations = 0.0;
    for (std::size_t i = 0; i < length; ++i) {
        const double value = static_cast<double>(values[i]);
        deviations += value >= average ? value - average : average - value;
    }
    return std::nearbyint((deviations / static_cast<double>(length)) * 100.0) / 100.0;
}
