#ifndef MONTE_CARLO_RISK_IMPL_H
#define MONTE_CARLO_RISK_IMPL_H

#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MC_MIN_RETURN_COUNT 20
#define MC_MAX_RETURN_COUNT 64
#define MC_MIN_SIMULATION_COUNT 20
#define MC_MAX_SIMULATION_COUNT 128
#define MC_MAX_VALID_INPUT_LENGTH 197
#define MC_MAX_PARSEABLE_INPUT_LENGTH 198

static int64_t monte_carlo_risk_impl(const double *input, size_t input_length,
                                     double *output, size_t output_capacity,
                                     int expected_shortfall)
{
    if (input == NULL || input_length < 45 || input_length > MC_MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < input_length; ++index) {
        if (!isfinite(input[index])) return -1;
    }

    const double portfolio = input[0];
    const double confidence = input[1];
    const double horizon = input[2];
    const double simulation_value = input[3];
    const double return_count_value = input[4];
    if (portfolio < 100.0 || portfolio > 1000000.0 ||
        confidence < 0.5 || confidence > 0.95 ||
        horizon < 1.0 || horizon > 10.0 ||
        simulation_value < MC_MIN_SIMULATION_COUNT || simulation_value > MC_MAX_SIMULATION_COUNT ||
        return_count_value < MC_MIN_RETURN_COUNT || return_count_value > MC_MAX_RETURN_COUNT) return -1;

    const size_t simulation_count = (size_t)simulation_value;
    const size_t return_count = (size_t)return_count_value;
    if (simulation_value != (double)simulation_count ||
        return_count_value != (double)return_count) return -1;
    const size_t expected_length = 5 + return_count + simulation_count;
    if (input_length != expected_length || input_length > MC_MAX_VALID_INPUT_LENGTH) return -1;

    double returns[MC_MAX_RETURN_COUNT];
    double draws[MC_MAX_SIMULATION_COUNT];
    double simulated[MC_MAX_SIMULATION_COUNT];
    double sum = 0.0;
    for (size_t index = 0; index < return_count; ++index) {
        const double value = input[5 + index];
        if (value < -0.25 || value > 0.25) return -1;
        returns[index] = value;
        sum += value;
    }
    for (size_t index = 0; index < simulation_count; ++index) {
        const double value = input[5 + return_count + index];
        if (value < -3.0 || value > 3.0) return -1;
        draws[index] = value;
    }
    const double mean = sum / (double)return_count;
    double squared_deviation = 0.0;
    for (size_t index = 0; index < return_count; ++index) {
        const double delta = returns[index] - mean;
        squared_deviation += delta * delta;
    }
    const double volatility = sqrt(squared_deviation / (double)(return_count - 1));
    if (!isfinite(volatility) || volatility == 0.0) return -1;

    for (size_t index = 0; index < simulation_count; ++index)
        simulated[index] = mean + volatility * draws[index];
    for (size_t index = 1; index < simulation_count; ++index) {
        const double value = simulated[index];
        size_t position = index;
        while (position > 0 && simulated[position - 1] > value) {
            simulated[position] = simulated[position - 1];
            --position;
        }
        simulated[position] = value;
    }

    const double tail_value = floor((1.0 - confidence) * (double)simulation_count);
    if (tail_value < 1.0 || tail_value > (double)simulation_count) return -1;
    const size_t tail_count = (size_t)tail_value;
    double metric;
    if (expected_shortfall) {
        double tail_sum = 0.0;
        for (size_t index = 0; index < tail_count; ++index) tail_sum += simulated[index];
        metric = -(tail_sum / (double)tail_count) * portfolio * sqrt(horizon);
    } else {
        metric = -simulated[tail_count - 1] * portfolio * sqrt(horizon);
    }
    if (!isfinite(metric)) return -1;
    if (output == NULL || output_capacity < 1) return -2;
    output[0] = metric;
    return 1;
}

#endif
