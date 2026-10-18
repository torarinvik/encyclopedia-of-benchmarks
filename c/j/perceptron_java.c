#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define MAX_SAMPLES 8u
#define MAX_FEATURES 4u
#define MAX_QUERIES 4u
#define MAX_INPUT_LENGTH 61u
#define MAX_PARSEABLE_INPUT_LENGTH 62u
#define MAX_OUTPUT_LENGTH 13u

int64_t perceptron_java(const double *input, size_t input_length,
                        double *output, size_t output_capacity) {
    if (input == NULL || input_length < 9u || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < input_length; ++index) {
        if (!isfinite(input[index])) return -1;
    }

    const double learning_rate = input[0];
    const double epochs_value = input[1];
    const double samples_value = input[2];
    const double features_value = input[3];
    if (learning_rate != 0.25 && learning_rate != 0.5 &&
        learning_rate != 0.75 && learning_rate != 1.0) return -1;
    if (epochs_value < 1.0 || epochs_value > 12.0 || epochs_value != (double)(size_t)epochs_value ||
        samples_value < 2.0 || samples_value > (double)MAX_SAMPLES || samples_value != (double)(size_t)samples_value ||
        features_value < 1.0 || features_value > (double)MAX_FEATURES || features_value != (double)(size_t)features_value) return -1;

    const size_t max_epochs = (size_t)epochs_value;
    const size_t sample_count = (size_t)samples_value;
    const size_t feature_count = (size_t)features_value;
    const size_t features_start = 4u;
    const size_t labels_start = features_start + sample_count * feature_count;
    const size_t query_count_index = labels_start + sample_count;
    if (input_length <= query_count_index) return -1;

    const double query_count_value = input[query_count_index];
    if (query_count_value < 1.0 || query_count_value > (double)MAX_QUERIES ||
        query_count_value != (double)(size_t)query_count_value) return -1;
    const size_t query_count = (size_t)query_count_value;
    const size_t query_start = query_count_index + 1u;
    if (input_length != query_start + query_count * feature_count || input_length > MAX_INPUT_LENGTH) return -1;

    for (size_t row = 0; row < sample_count; ++row) {
        for (size_t feature = 0; feature < feature_count; ++feature) {
            const double value = input[features_start + row * feature_count + feature];
            if (value < -2.0 || value > 2.0 || value != (double)(int)value) return -1;
        }
    }
    for (size_t row = 0; row < sample_count; ++row) {
        const double label = input[labels_start + row];
        if (label != 0.0 && label != 1.0) return -1;
    }
    for (size_t row = 0; row < query_count; ++row) {
        for (size_t feature = 0; feature < feature_count; ++feature) {
            const double value = input[query_start + row * feature_count + feature];
            if (value < -2.0 || value > 2.0 || value != (double)(int)value) return -1;
        }
    }

    double weights[MAX_FEATURES] = {0.0};
    double bias = 0.0;
    size_t epochs_run = 0u;
    int converged = 0;
    for (size_t epoch = 0; epoch < max_epochs; ++epoch) {
        int updated = 0;
        for (size_t row = 0; row < sample_count; ++row) {
            double weighted_sum = bias;
            for (size_t feature = 0; feature < feature_count; ++feature) {
                weighted_sum += weights[feature] * input[features_start + row * feature_count + feature];
            }
            const int prediction = weighted_sum >= 0.0 ? 1 : 0;
            const int label = (int)input[labels_start + row];
            const int error = label - prediction;
            if (error != 0) {
                for (size_t feature = 0; feature < feature_count; ++feature) {
                    weights[feature] += learning_rate * (double)error * input[features_start + row * feature_count + feature];
                }
                bias += learning_rate * (double)error;
                updated = 1;
            }
        }
        epochs_run = epoch + 1u;
        if (!updated) {
            converged = 1;
            break;
        }
    }

    double staged[MAX_OUTPUT_LENGTH];
    size_t result_length = 0u;
    staged[result_length++] = (double)feature_count;
    for (size_t feature = 0; feature < feature_count; ++feature) staged[result_length++] = weights[feature];
    staged[result_length++] = bias;
    staged[result_length++] = (double)epochs_run;
    staged[result_length++] = (double)converged;
    staged[result_length++] = (double)query_count;
    for (size_t row = 0; row < query_count; ++row) {
        double weighted_sum = bias;
        for (size_t feature = 0; feature < feature_count; ++feature) {
            weighted_sum += weights[feature] * input[query_start + row * feature_count + feature];
        }
        staged[result_length++] = weighted_sum >= 0.0 ? 1.0 : 0.0;
    }

    if (output == NULL || output_capacity < result_length) return -2;
    for (size_t index = 0; index < result_length; ++index) output[index] = staged[index];
    return (int64_t)result_length;
}
