#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VECTOR_LENGTH 32
#define MAX_PARSEABLE_INPUT_LENGTH 102

static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static double rounded_add(double left, double right)
{
    volatile double result = left + right;
    return result;
}

static double rounded_subtract(double left, double right)
{
    volatile double result = left - right;
    return result;
}

static double rounded_divide(double left, double right)
{
    volatile double result = left / right;
    return result;
}

int64_t rmsprop(const double *input, size_t input_length,
                double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }

    const double count_value = input[0];
    const double state_mode_value = input[1];
    if (count_value < 0.0 || count_value > MAX_VECTOR_LENGTH) return -1;
    const size_t count = (size_t)count_value;
    if (count_value != (double)count) return -1;
    if (state_mode_value != 0.0 && state_mode_value != 1.0) return -1;
    const int state_mode = state_mode_value == 1.0;

    const size_t expected_length = 5 + 2 * count + (state_mode ? count : 0);
    if (input_length != expected_length) return -1;

    const double learning_rate = input[2];
    const double rho = input[3];
    const double epsilon = input[4];
    if (learning_rate < 1e-6 || learning_rate > 1.0 ||
        rho < 0.0 || rho > 0.99 || epsilon < 1e-8 || epsilon > 1.0) return -1;

    const size_t gradients_start = 5 + count;
    const size_t moving_average_start = 5 + 2 * count;
    double moving_average[MAX_VECTOR_LENGTH];
    double updated_params[MAX_VECTOR_LENGTH];
    double updated_average[MAX_VECTOR_LENGTH];
    for (size_t i = 0; i < count; ++i) {
        const double parameter = input[5 + i];
        const double gradient = input[gradients_start + i];
        if (parameter < -100.0 || parameter > 100.0 ||
            gradient < -100.0 || gradient > 100.0) return -1;
        moving_average[i] = state_mode ? input[moving_average_start + i] : 0.0;
        if (moving_average[i] < 0.0 || moving_average[i] > 10000.0) return -1;
    }

    if (output == NULL || output_capacity < 2 * count) return -2;

    for (size_t i = 0; i < count; ++i) {
        const double parameter = input[5 + i];
        const double gradient = input[gradients_start + i];
        const double weighted_previous = rounded_multiply(rho, moving_average[i]);
        const double one_minus_rho = rounded_subtract(1.0, rho);
        const double squared_gradient = pow(gradient, 2.0);
        const double weighted_gradient = rounded_multiply(one_minus_rho, squared_gradient);
        const double new_average = rounded_add(weighted_previous, weighted_gradient);
        const double sqrt_argument = rounded_add(new_average, epsilon);
        const double denominator = sqrt(sqrt_argument);
        const double scale = rounded_divide(learning_rate, denominator);
        const double step = rounded_multiply(scale, gradient);
        updated_params[i] = rounded_subtract(parameter, step);
        updated_average[i] = new_average;
    }

    for (size_t i = 0; i < count; ++i) {
        output[i] = updated_params[i];
        output[count + i] = updated_average[i];
    }
    return (int64_t)(2 * count);
}
