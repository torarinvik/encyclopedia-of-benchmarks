#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_group_count = 8;
constexpr std::size_t max_parameter_count = 16;
constexpr std::size_t max_group_vector_elements = 32;
constexpr std::size_t max_call_count = 8;
constexpr std::size_t max_valid_input_length = 269;
constexpr std::size_t max_parseable_input_length = 270;

double rounded_multiply(double left, double right) noexcept
{
    volatile double result = left * right;
    return result;
}

double rounded_add(double left, double right) noexcept
{
    volatile double result = left + right;
    return result;
}

double rounded_subtract(double left, double right) noexcept
{
    volatile double result = left - right;
    return result;
}
}

extern "C" std::int64_t momentum_sgd(const double *input, std::size_t input_length,
                                      double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 5 || input_length > max_parseable_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i) {
        if (!std::isfinite(input[i])) return -1;
    }

    const double group_count_value = input[0];
    const double parameter_count_value = input[1];
    const double call_count_value = input[2];
    if (group_count_value < 1.0 || group_count_value > static_cast<double>(max_group_count) ||
        parameter_count_value < 1.0 || parameter_count_value > static_cast<double>(max_parameter_count) ||
        call_count_value < 1.0 || call_count_value > static_cast<double>(max_call_count)) return -1;

    const std::size_t group_count = static_cast<std::size_t>(group_count_value);
    const std::size_t parameter_count = static_cast<std::size_t>(parameter_count_value);
    const std::size_t call_count = static_cast<std::size_t>(call_count_value);
    if (group_count_value != static_cast<double>(group_count) ||
        parameter_count_value != static_cast<double>(parameter_count) ||
        call_count_value != static_cast<double>(call_count)) return -1;
    if (group_count * parameter_count > max_group_vector_elements ||
        call_count < group_count) return -1;

    const std::size_t expected_length = 5 + call_count * (1 + 2 * parameter_count);
    if (input_length != expected_length || input_length > max_valid_input_length) return -1;

    const double learning_rate = input[3];
    const double momentum = input[4];
    if (learning_rate < 1e-6 || learning_rate > 1.0 ||
        momentum < 0.0 || momentum > 0.99) return -1;

    bool seen[max_group_count] = {};
    std::size_t cursor = 5;
    for (std::size_t call = 0; call < call_count; ++call) {
        const double id_value = input[cursor++];
        if (id_value < 0.0 || id_value >= static_cast<double>(group_count)) return -1;
        const std::size_t param_id = static_cast<std::size_t>(id_value);
        if (id_value != static_cast<double>(param_id)) return -1;
        seen[param_id] = true;

        for (std::size_t i = 0; i < parameter_count; ++i) {
            const double parameter = input[cursor++];
            if (parameter < -1000.0 || parameter > 1000.0) return -1;
        }
        for (std::size_t i = 0; i < parameter_count; ++i) {
            const double gradient = input[cursor++];
            if (gradient < -1000.0 || gradient > 1000.0) return -1;
        }
    }
    for (std::size_t id = 0; id < group_count; ++id) {
        if (!seen[id]) return -1;
    }

    const std::size_t group_elements = group_count * parameter_count;
    const std::size_t output_elements = 2 * group_elements;
    if (output == nullptr || output_capacity < output_elements) return -2;

    double velocity[max_group_vector_elements] = {};
    double last_params[max_group_vector_elements] = {};
    cursor = 5;
    for (std::size_t call = 0; call < call_count; ++call) {
        const std::size_t param_id = static_cast<std::size_t>(input[cursor++]);
        const std::size_t group_offset = param_id * parameter_count;
        double event_params[max_parameter_count];
        for (std::size_t i = 0; i < parameter_count; ++i)
            event_params[i] = input[cursor++];

        for (std::size_t i = 0; i < parameter_count; ++i) {
            const std::size_t index = group_offset + i;
            const double gradient = input[cursor++];
            const double previous_term = rounded_multiply(momentum, velocity[index]);
            const double gradient_term = rounded_multiply(learning_rate, gradient);
            velocity[index] = rounded_subtract(previous_term, gradient_term);
            last_params[index] = rounded_add(event_params[i], velocity[index]);
        }
    }

    for (std::size_t i = 0; i < group_elements; ++i) {
        output[i] = last_params[i];
        output[group_elements + i] = velocity[i];
    }
    return static_cast<std::int64_t>(output_elements);
}
