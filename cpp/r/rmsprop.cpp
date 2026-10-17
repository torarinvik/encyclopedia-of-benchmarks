#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vector_length = 32;
constexpr std::size_t max_parseable_input_length = 102;

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

double rounded_divide(double left, double right) noexcept
{
    volatile double result = left / right;
    return result;
}
}

extern "C" std::int64_t rmsprop(const double *input, std::size_t input_length,
                                 double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 5 || input_length > max_parseable_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i) {
        if (!std::isfinite(input[i])) return -1;
    }

    const double count_value = input[0];
    const double state_mode_value = input[1];
    if (count_value < 0.0 || count_value > static_cast<double>(max_vector_length)) return -1;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (count_value != static_cast<double>(count)) return -1;
    if (state_mode_value != 0.0 && state_mode_value != 1.0) return -1;
    const bool state_mode = state_mode_value == 1.0;

    const std::size_t expected_length = 5 + 2 * count + (state_mode ? count : 0);
    if (input_length != expected_length) return -1;

    const double learning_rate = input[2];
    const double rho = input[3];
    const double epsilon = input[4];
    if (learning_rate < 1e-6 || learning_rate > 1.0 ||
        rho < 0.0 || rho > 0.99 || epsilon < 1e-8 || epsilon > 1.0) return -1;

    const std::size_t gradients_start = 5 + count;
    const std::size_t moving_average_start = 5 + 2 * count;
    double moving_average[max_vector_length];
    double updated_params[max_vector_length];
    double updated_average[max_vector_length];
    for (std::size_t i = 0; i < count; ++i) {
        const double parameter = input[5 + i];
        const double gradient = input[gradients_start + i];
        if (parameter < -100.0 || parameter > 100.0 ||
            gradient < -100.0 || gradient > 100.0) return -1;
        moving_average[i] = state_mode ? input[moving_average_start + i] : 0.0;
        if (moving_average[i] < 0.0 || moving_average[i] > 10000.0) return -1;
    }

    if (output == nullptr || output_capacity < 2 * count) return -2;

    for (std::size_t i = 0; i < count; ++i) {
        const double parameter = input[5 + i];
        const double gradient = input[gradients_start + i];
        const double weighted_previous = rounded_multiply(rho, moving_average[i]);
        const double one_minus_rho = rounded_subtract(1.0, rho);
        const double squared_gradient = std::pow(gradient, 2.0);
        const double weighted_gradient = rounded_multiply(one_minus_rho, squared_gradient);
        const double new_average = rounded_add(weighted_previous, weighted_gradient);
        const double sqrt_argument = rounded_add(new_average, epsilon);
        const double denominator = std::sqrt(sqrt_argument);
        const double scale = rounded_divide(learning_rate, denominator);
        const double step = rounded_multiply(scale, gradient);
        updated_params[i] = rounded_subtract(parameter, step);
        updated_average[i] = new_average;
    }

    for (std::size_t i = 0; i < count; ++i) {
        output[i] = updated_params[i];
        output[count + i] = updated_average[i];
    }
    return static_cast<std::int64_t>(2 * count);
}
