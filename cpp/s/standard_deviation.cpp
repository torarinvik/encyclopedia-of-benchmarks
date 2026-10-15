#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 64;
constexpr std::int64_t MAX_ABS_VALUE = 1'000'000;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double standard_deviation(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double sum = 0.0;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += static_cast<double>(values[i]);
    }
    const double average = sum / static_cast<double>(length);
    double squared_deviations = 0.0;
    for (std::size_t i = 0; i < length; ++i) {
        const double difference = static_cast<double>(values[i]) - average;
        squared_deviations += std::pow(difference, 2.0);
    }
    return std::sqrt(squared_deviations / static_cast<double>(length));
}
