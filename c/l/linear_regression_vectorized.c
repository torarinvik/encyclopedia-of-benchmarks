/* Bounded f64 gradient descent adapted from the pinned vectorized routine. */
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_PARSEABLE_INPUT_LENGTH = 45,
    MAX_SAMPLES = 8,
    MAX_FEATURES = 4,
    MAX_FEATURE_VALUES = MAX_SAMPLES * MAX_FEATURES
};

int64_t linear_regression_vectorized(const double *input, size_t length,
                                     double *output, size_t output_capacity)
{
    if (input == NULL || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const double sample_value = input[0];
    const double feature_value = input[1];
    const double iteration_value = input[2];
    if (sample_value != sample_value || sample_value < 2.0 || sample_value > MAX_SAMPLES ||
        feature_value != feature_value || feature_value < 2.0 || feature_value > MAX_FEATURES ||
        iteration_value != iteration_value || iteration_value < 10.0 || iteration_value > 128.0) return -1;
    const size_t sample_count = (size_t)sample_value;
    const size_t feature_count = (size_t)feature_value;
    const size_t iterations = (size_t)iteration_value;
    if ((double)sample_count != sample_value || (double)feature_count != feature_value ||
        (double)iterations != iteration_value) return -1;
    if (length != 4 + sample_count * feature_count + sample_count) return -1;

    const double alpha = input[3];
    if (alpha != alpha || alpha < 0.0001 || alpha > 0.01) return -1;

    double features[MAX_FEATURE_VALUES];
    double labels[MAX_SAMPLES];
    const size_t feature_values = sample_count * feature_count;
    for (size_t index = 0; index < feature_values; ++index) {
        const double value = input[4 + index];
        if (value != value || value < -1.0 || value > 1.0) return -1;
        features[index] = value;
    }
    for (size_t row = 0; row < sample_count; ++row)
        if (features[row * feature_count] != 1.0) return -1;
    for (size_t row = 0; row < sample_count; ++row) {
        const double value = input[4 + feature_values + row];
        if (value != value || value < -1.0 || value > 1.0) return -1;
        labels[row] = value;
    }

    if (output == NULL || output_capacity < feature_count) return -2;

    double theta[MAX_FEATURES] = {0.0, 0.0, 0.0, 0.0};
    double errors[MAX_SAMPLES];
    double gradients[MAX_FEATURES];
    for (size_t iteration = 0; iteration < iterations; ++iteration) {
        for (size_t row = 0; row < sample_count; ++row) {
            double prediction = 0.0;
            for (size_t column = 0; column < feature_count; ++column)
                prediction += features[row * feature_count + column] * theta[column];
            errors[row] = prediction - labels[row];
        }
        for (size_t column = 0; column < feature_count; ++column) {
            double gradient = 0.0;
            for (size_t row = 0; row < sample_count; ++row)
                gradient += features[row * feature_count + column] * errors[row];
            gradients[column] = gradient / (double)sample_count;
        }
        for (size_t column = 0; column < feature_count; ++column)
            theta[column] -= alpha * gradients[column];
    }
    for (size_t column = 0; column < feature_count; ++column) output[column] = theta[column];
    return (int64_t)feature_count;
}
