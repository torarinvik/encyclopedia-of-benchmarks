#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t output_error = -2;
constexpr std::size_t max_parseable_input_length = 69;
}

extern "C" std::int64_t historical_var(const double *input, std::size_t input_length,
                                        double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 24 || input_length > max_parseable_input_length) return invalid_result;
    for (std::size_t i = 0; i < input_length; ++i)
        if (!std::isfinite(input[i])) return invalid_result;
    const double portfolio_value = input[0];
    const double confidence_level = input[1];
    const double time_horizon = input[2];
    const double count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || std::floor(count_value) != count_value) return invalid_result;
    const auto return_count = static_cast<std::size_t>(count_value);
    if (input_length != 4 + return_count || portfolio_value < 100.0 || portfolio_value > 1000000.0 ||
        confidence_level < 0.5 || confidence_level > 0.95 || time_horizon < 1.0 || time_horizon > 10.0)
        return invalid_result;
    double sorted_returns[64];
    for (std::size_t i = 0; i < return_count; ++i) {
        const double value = input[4 + i];
        if (value < -0.25 || value > 0.25) return invalid_result;
        sorted_returns[i] = value;
    }
    const auto index = static_cast<int>(std::floor((1.0 - confidence_level) * static_cast<double>(return_count)));
    if (index < 1) return invalid_result;
    std::sort(sorted_returns, sorted_returns + return_count);
    double result = -sorted_returns[index - 1] * portfolio_value;
    result *= std::sqrt(time_horizon);
    if (output == nullptr || output_capacity < 1) return output_error;
    output[0] = result;
    return 1;
}
