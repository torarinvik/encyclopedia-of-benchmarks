// Biased autocorrelation with variance and covariance divided by n.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 64; }

extern "C" double autocorrelation(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 4 || length > max_length + 2) return -1.0e300;
    const auto count_value = values[0];
    const auto lag_value = values[1];
    if (count_value < 2 || count_value > static_cast<std::int64_t>(max_length) ||
        length != static_cast<std::size_t>(count_value) + 2 || lag_value < 0 || lag_value >= count_value)
        return -1.0e300;
    const auto count = static_cast<std::size_t>(count_value);
    const auto lag = static_cast<std::size_t>(lag_value);
    double sum = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = values[index + 2];
        if (value < -1000 || value > 1000) return -1.0e300;
        sum += static_cast<double>(value);
    }
    const double mean = sum / static_cast<double>(count);
    double variance_sum = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const double difference = static_cast<double>(values[index + 2]) - mean;
        variance_sum += difference * difference;
    }
    if (variance_sum == 0.0) return -1.0e300;
    const double variance = variance_sum / static_cast<double>(count);
    double covariance_sum = 0.0;
    for (std::size_t index = lag; index < count; ++index) {
        const double current = static_cast<double>(values[index + 2]) - mean;
        const double delayed = static_cast<double>(values[index - lag + 2]) - mean;
        covariance_sum += current * delayed;
    }
    return (covariance_sum / static_cast<double>(count)) / variance;
}
