#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_GROUP_COUNT 8
#define MAX_PARAMETER_COUNT 16
#define MAX_GROUP_VECTOR_ELEMENTS 32
#define MAX_CALL_COUNT 8
#define MAX_VALID_INPUT_LENGTH 269
#define MAX_PARSEABLE_INPUT_LENGTH 270

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

int64_t momentum_sgd(const double *input, size_t input_length,
                     double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 5 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }

    const double group_count_value = input[0];
    const double parameter_count_value = input[1];
    const double call_count_value = input[2];
    if (group_count_value < 1.0 || group_count_value > MAX_GROUP_COUNT ||
        parameter_count_value < 1.0 || parameter_count_value > MAX_PARAMETER_COUNT ||
        call_count_value < 1.0 || call_count_value > MAX_CALL_COUNT) return -1;

    const size_t group_count = (size_t)group_count_value;
    const size_t parameter_count = (size_t)parameter_count_value;
    const size_t call_count = (size_t)call_count_value;
    if (group_count_value != (double)group_count ||
        parameter_count_value != (double)parameter_count ||
        call_count_value != (double)call_count) return -1;
    if (group_count * parameter_count > MAX_GROUP_VECTOR_ELEMENTS ||
        call_count < group_count) return -1;

    const size_t expected_length = 5 + call_count * (1 + 2 * parameter_count);
    if (input_length != expected_length || input_length > MAX_VALID_INPUT_LENGTH) return -1;

    const double learning_rate = input[3];
    const double momentum = input[4];
    if (learning_rate < 1e-6 || learning_rate > 1.0 ||
        momentum < 0.0 || momentum > 0.99) return -1;

    bool seen[MAX_GROUP_COUNT] = { false };
    size_t cursor = 5;
    for (size_t call = 0; call < call_count; ++call) {
        const double id_value = input[cursor++];
        if (id_value < 0.0 || id_value >= (double)group_count) return -1;
        const size_t param_id = (size_t)id_value;
        if (id_value != (double)param_id) return -1;
        seen[param_id] = true;

        for (size_t i = 0; i < parameter_count; ++i) {
            const double parameter = input[cursor++];
            if (parameter < -1000.0 || parameter > 1000.0) return -1;
        }
        for (size_t i = 0; i < parameter_count; ++i) {
            const double gradient = input[cursor++];
            if (gradient < -1000.0 || gradient > 1000.0) return -1;
        }
    }
    for (size_t id = 0; id < group_count; ++id) {
        if (!seen[id]) return -1;
    }

    const size_t group_elements = group_count * parameter_count;
    const size_t output_elements = 2 * group_elements;
    if (output == NULL || output_capacity < output_elements) return -2;

    double velocity[MAX_GROUP_VECTOR_ELEMENTS] = { 0.0 };
    double last_params[MAX_GROUP_VECTOR_ELEMENTS] = { 0.0 };
    cursor = 5;
    for (size_t call = 0; call < call_count; ++call) {
        const size_t param_id = (size_t)input[cursor++];
        const size_t group_offset = param_id * parameter_count;
        double event_params[MAX_PARAMETER_COUNT];
        for (size_t i = 0; i < parameter_count; ++i)
            event_params[i] = input[cursor++];

        for (size_t i = 0; i < parameter_count; ++i) {
            const size_t index = group_offset + i;
            const double gradient = input[cursor++];
            const double previous_term = rounded_multiply(momentum, velocity[index]);
            const double gradient_term = rounded_multiply(learning_rate, gradient);
            velocity[index] = rounded_subtract(previous_term, gradient_term);
            last_params[index] = rounded_add(event_params[i], velocity[index]);
        }
    }

    for (size_t i = 0; i < group_elements; ++i) {
        output[i] = last_params[i];
        output[group_elements + i] = velocity[i];
    }
    return (int64_t)output_elements;
}
