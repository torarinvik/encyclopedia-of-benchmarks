#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_length = 67;
constexpr std::int64_t max_sample_count = 64;
constexpr double scale = 1'000'000.0;
constexpr std::int64_t min_return_micro = -200'000;
constexpr std::int64_t max_return_micro = 200'000;
constexpr std::int64_t min_risk_free_micro = -100'000;
constexpr std::int64_t max_risk_free_micro = 100'000;
constexpr double invalid_result = -1.0e300;
}

extern "C" double sharpe_ratio(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > max_parseable_length) return invalid_result;
    const auto count_value = values[0];
    if (count_value < 2 || count_value > max_sample_count
        || length != static_cast<std::size_t>(count_value) + 2) return invalid_result;
    const auto count = static_cast<std::size_t>(count_value);
    const auto risk_free_micro = values[count + 1];
    if (risk_free_micro < min_risk_free_micro || risk_free_micro > max_risk_free_micro)
        return invalid_result;

    double sum = 0.0;
    bool constant_returns = true;
    for (std::size_t index = 0; index < count; ++index) {
        const auto return_micro = values[index + 1];
        if (return_micro < min_return_micro || return_micro > max_return_micro)
            return invalid_result;
        if (return_micro != values[1]) constant_returns = false;
        sum += static_cast<double>(return_micro) / scale;
    }
    if (constant_returns) return invalid_result;

    const double mean = sum / static_cast<double>(count);
    const double risk_free_rate = static_cast<double>(risk_free_micro) / scale;
    const double excess_return = mean - risk_free_rate;
    double squared_deviations = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const double return_value = static_cast<double>(values[index + 1]) / scale;
        const double difference = return_value - mean;
        squared_deviations += std::pow(difference, 2.0);
    }
    const double variance = squared_deviations / static_cast<double>(count - 1);
    const double standard_deviation = std::sqrt(variance);
    if (standard_deviation == 0.0) return invalid_result;
    return excess_return / standard_deviation;
}
