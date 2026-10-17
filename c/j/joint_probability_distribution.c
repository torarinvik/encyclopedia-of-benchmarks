#include <stddef.h>
#include <stdint.h>

#define MAX_SUPPORT_LENGTH 4
#define MAX_PARSEABLE_INPUT_LENGTH 20
#define MAX_OUTPUT_ELEMENTS (3 * MAX_SUPPORT_LENGTH * MAX_SUPPORT_LENGTH)

static int parse_count(double raw, size_t *count)
{
    if (raw != raw || raw < 1.0 || raw > MAX_SUPPORT_LENGTH) return 0;
    const int parsed = (int)raw;
    if ((double)parsed != raw) return 0;
    *count = (size_t)parsed;
    return 1;
}

static int parse_support(double raw, int64_t *support)
{
    if (raw != raw || raw < -1000.0 || raw > 1000.0) return 0;
    const int64_t parsed = (int64_t)raw;
    if ((double)parsed != raw) return 0;
    *support = parsed;
    return 1;
}

static int valid_probability(double value)
{
    return value == value && value >= -1000000.0 && value <= 1000000.0;
}

int64_t joint_probability_distribution(const double *input, size_t input_length,
                                       double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    size_t x_count, y_count;
    if (!parse_count(input[0], &x_count) || !parse_count(input[1], &y_count)) return -1;
    if (input_length != 2 + 2 * x_count + 2 * y_count) return -1;

    const size_t x_start = 2;
    const size_t y_start = x_start + x_count;
    const size_t x_probability_start = y_start + y_count;
    const size_t y_probability_start = x_probability_start + x_count;
    int64_t x_values[MAX_SUPPORT_LENGTH], y_values[MAX_SUPPORT_LENGTH];
    double x_probabilities[MAX_SUPPORT_LENGTH], y_probabilities[MAX_SUPPORT_LENGTH];

    for (size_t index = 0; index < x_count; ++index) {
        if (!parse_support(input[x_start + index], &x_values[index]) ||
            !valid_probability(input[x_probability_start + index])) return -1;
        x_probabilities[index] = input[x_probability_start + index];
        for (size_t previous = 0; previous < index; ++previous)
            if (x_values[previous] == x_values[index]) return -1;
    }
    for (size_t index = 0; index < y_count; ++index) {
        if (!parse_support(input[y_start + index], &y_values[index]) ||
            !valid_probability(input[y_probability_start + index])) return -1;
        y_probabilities[index] = input[y_probability_start + index];
        for (size_t previous = 0; previous < index; ++previous)
            if (y_values[previous] == y_values[index]) return -1;
    }

    const size_t required = 3 * x_count * y_count;
    if (required > MAX_OUTPUT_ELEMENTS) return -1;
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    for (size_t x_index = 0; x_index < x_count; ++x_index) {
        for (size_t y_index = 0; y_index < y_count; ++y_index) {
            output[position++] = (double)x_values[x_index];
            output[position++] = (double)y_values[y_index];
            output[position++] = x_probabilities[x_index] * y_probabilities[y_index];
        }
    }
    return (int64_t)required;
}
