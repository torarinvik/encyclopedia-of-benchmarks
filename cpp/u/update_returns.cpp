#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_returns = 2;
constexpr std::size_t max_returns = 60;
constexpr std::size_t max_input_length = 62;
constexpr std::size_t max_output_length = 63;
constexpr double z_95 = 1.6448536269514722;
}

// Project the updated returns, sample statistics, and post-update parametric VaR.
extern "C" std::int64_t update_returns(const double *input, std::size_t input_length,
                                       double *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 + min_returns || input_length > max_input_length)
        return -1;
    for (std::size_t i = 0; i < input_length; ++i) {
        if (!std::isfinite(input[i])) return -1;
    }
    if (input[0] < static_cast<double>(min_returns) || input[0] > static_cast<double>(max_returns) ||
        input[0] != std::trunc(input[0])) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (input_length != count + 1) return -1;

    double returns[max_returns];
    double sum = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const double value = input[i + 1];
        if (value < -0.25 || value > 0.25) return -1;
        returns[i] = value;
        sum += value;
    }
    const double mean = sum / static_cast<double>(count);
    double squared_deviation_sum = 0.0;
    for (std::size_t i = 0; i < count; ++i) {
        const double deviation = returns[i] - mean;
        squared_deviation_sum += deviation * deviation;
    }
    const double volatility = std::sqrt(squared_deviation_sum / static_cast<double>(count - 1));
    if (!std::isfinite(mean) || !std::isfinite(volatility) || volatility == 0.0) return -1;
    const double var = 100000.0 * (z_95 * volatility - mean);
    if (!std::isfinite(var)) return -1;

    double staged[max_output_length];
    for (std::size_t i = 0; i < count; ++i) staged[i] = returns[i];
    staged[count] = mean;
    staged[count + 1] = volatility;
    staged[count + 2] = var;
    const std::size_t result_length = count + 3;
    if (output == nullptr || output_capacity < result_length) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(result_length);
}
