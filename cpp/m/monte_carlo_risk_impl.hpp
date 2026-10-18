#ifndef MONTE_CARLO_RISK_IMPL_HPP
#define MONTE_CARLO_RISK_IMPL_HPP

#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t mc_min_return_count = 20;
constexpr std::size_t mc_max_return_count = 64;
constexpr std::size_t mc_min_simulation_count = 20;
constexpr std::size_t mc_max_simulation_count = 128;
constexpr std::size_t mc_max_valid_input_length = 197;
constexpr std::size_t mc_max_parseable_input_length = 198;

std::int64_t monte_carlo_risk_impl(const double *input, std::size_t input_length,
                                   double *output, std::size_t output_capacity,
                                   bool expected_shortfall) noexcept
{
    if (input == nullptr || input_length < 45 || input_length > mc_max_parseable_input_length) return -1;
    for (std::size_t index = 0; index < input_length; ++index) {
        if (!std::isfinite(input[index])) return -1;
    }

    const double portfolio = input[0];
    const double confidence = input[1];
    const double horizon = input[2];
    const double simulation_value = input[3];
    const double return_count_value = input[4];
    if (portfolio < 100.0 || portfolio > 1000000.0 ||
        confidence < 0.5 || confidence > 0.95 ||
        horizon < 1.0 || horizon > 10.0 ||
        simulation_value < static_cast<double>(mc_min_simulation_count) ||
        simulation_value > static_cast<double>(mc_max_simulation_count) ||
        return_count_value < static_cast<double>(mc_min_return_count) ||
        return_count_value > static_cast<double>(mc_max_return_count)) return -1;

    const std::size_t simulation_count = static_cast<std::size_t>(simulation_value);
    const std::size_t return_count = static_cast<std::size_t>(return_count_value);
    if (simulation_value != static_cast<double>(simulation_count) ||
        return_count_value != static_cast<double>(return_count)) return -1;
    const std::size_t expected_length = 5 + return_count + simulation_count;
    if (input_length != expected_length || input_length > mc_max_valid_input_length) return -1;

    double returns[mc_max_return_count];
    double draws[mc_max_simulation_count];
    double simulated[mc_max_simulation_count];
    double sum = 0.0;
    for (std::size_t index = 0; index < return_count; ++index) {
        const double value = input[5 + index];
        if (value < -0.25 || value > 0.25) return -1;
        returns[index] = value;
        sum += value;
    }
    for (std::size_t index = 0; index < simulation_count; ++index) {
        const double value = input[5 + return_count + index];
        if (value < -3.0 || value > 3.0) return -1;
        draws[index] = value;
    }
    const double mean = sum / static_cast<double>(return_count);
    double squared_deviation = 0.0;
    for (std::size_t index = 0; index < return_count; ++index) {
        const double delta = returns[index] - mean;
        squared_deviation += delta * delta;
    }
    const double volatility = std::sqrt(squared_deviation / static_cast<double>(return_count - 1));
    if (!std::isfinite(volatility) || volatility == 0.0) return -1;

    for (std::size_t index = 0; index < simulation_count; ++index)
        simulated[index] = mean + volatility * draws[index];
    for (std::size_t index = 1; index < simulation_count; ++index) {
        const double value = simulated[index];
        std::size_t position = index;
        while (position > 0 && simulated[position - 1] > value) {
            simulated[position] = simulated[position - 1];
            --position;
        }
        simulated[position] = value;
    }

    const double tail_value = std::floor((1.0 - confidence) * static_cast<double>(simulation_count));
    if (tail_value < 1.0 || tail_value > static_cast<double>(simulation_count)) return -1;
    const std::size_t tail_count = static_cast<std::size_t>(tail_value);
    double metric;
    if (expected_shortfall) {
        double tail_sum = 0.0;
        for (std::size_t index = 0; index < tail_count; ++index) tail_sum += simulated[index];
        metric = -(tail_sum / static_cast<double>(tail_count)) * portfolio * std::sqrt(horizon);
    } else {
        metric = -simulated[tail_count - 1] * portfolio * std::sqrt(horizon);
    }
    if (!std::isfinite(metric)) return -1;
    if (output == nullptr || output_capacity < 1) return -2;
    output[0] = metric;
    return 1;
}
}

#endif
