#include <cstddef>
#include <cstdint>
#include <cmath>

namespace {
constexpr std::size_t max_samples = 8;
constexpr std::size_t max_features = 4;
constexpr std::size_t max_queries = 4;
constexpr std::size_t max_input_length = 61;
constexpr std::size_t max_parseable_input_length = 62;
constexpr std::size_t max_output_length = 13;
}

extern "C" std::int64_t perceptron_java(const double* input, std::size_t input_length,
    double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 9 || input_length > max_parseable_input_length) return -1;
    for (std::size_t index = 0; index < input_length; ++index) {
        if (!std::isfinite(input[index])) return -1;
    }

    const double learning_rate = input[0];
    const double epochs_value = input[1];
    const double samples_value = input[2];
    const double features_value = input[3];
    if (learning_rate != 0.25 && learning_rate != 0.5 &&
        learning_rate != 0.75 && learning_rate != 1.0) return -1;
    if (epochs_value < 1.0 || epochs_value > 12.0 || epochs_value != static_cast<double>(static_cast<std::size_t>(epochs_value)) ||
        samples_value < 2.0 || samples_value > static_cast<double>(max_samples) || samples_value != static_cast<double>(static_cast<std::size_t>(samples_value)) ||
        features_value < 1.0 || features_value > static_cast<double>(max_features) || features_value != static_cast<double>(static_cast<std::size_t>(features_value))) return -1;

    const auto max_epochs = static_cast<std::size_t>(epochs_value);
    const auto sample_count = static_cast<std::size_t>(samples_value);
    const auto feature_count = static_cast<std::size_t>(features_value);
    constexpr std::size_t features_start = 4;
    const std::size_t labels_start = features_start + sample_count * feature_count;
    const std::size_t query_count_index = labels_start + sample_count;
    if (input_length <= query_count_index) return -1;

    const double query_count_value = input[query_count_index];
    if (query_count_value < 1.0 || query_count_value > static_cast<double>(max_queries) ||
        query_count_value != static_cast<double>(static_cast<std::size_t>(query_count_value))) return -1;
    const auto query_count = static_cast<std::size_t>(query_count_value);
    const std::size_t query_start = query_count_index + 1;
    if (input_length != query_start + query_count * feature_count || input_length > max_input_length) return -1;

    for (std::size_t row = 0; row < sample_count; ++row) {
        for (std::size_t feature = 0; feature < feature_count; ++feature) {
            const double value = input[features_start + row * feature_count + feature];
            if (value < -2.0 || value > 2.0 || value != static_cast<double>(static_cast<int>(value))) return -1;
        }
    }
    for (std::size_t row = 0; row < sample_count; ++row) {
        const double label = input[labels_start + row];
        if (label != 0.0 && label != 1.0) return -1;
    }
    for (std::size_t row = 0; row < query_count; ++row) {
        for (std::size_t feature = 0; feature < feature_count; ++feature) {
            const double value = input[query_start + row * feature_count + feature];
            if (value < -2.0 || value > 2.0 || value != static_cast<double>(static_cast<int>(value))) return -1;
        }
    }

    double weights[max_features]{};
    double bias = 0.0;
    std::size_t epochs_run = 0;
    bool converged = false;
    for (std::size_t epoch = 0; epoch < max_epochs; ++epoch) {
        bool updated = false;
        for (std::size_t row = 0; row < sample_count; ++row) {
            double weighted_sum = bias;
            for (std::size_t feature = 0; feature < feature_count; ++feature) {
                weighted_sum += weights[feature] * input[features_start + row * feature_count + feature];
            }
            const int prediction = weighted_sum >= 0.0 ? 1 : 0;
            const int label = static_cast<int>(input[labels_start + row]);
            const int error = label - prediction;
            if (error != 0) {
                for (std::size_t feature = 0; feature < feature_count; ++feature) {
                    weights[feature] += learning_rate * static_cast<double>(error) * input[features_start + row * feature_count + feature];
                }
                bias += learning_rate * static_cast<double>(error);
                updated = true;
            }
        }
        epochs_run = epoch + 1;
        if (!updated) {
            converged = true;
            break;
        }
    }

    double staged[max_output_length];
    std::size_t result_length = 0;
    staged[result_length++] = static_cast<double>(feature_count);
    for (std::size_t feature = 0; feature < feature_count; ++feature) staged[result_length++] = weights[feature];
    staged[result_length++] = bias;
    staged[result_length++] = static_cast<double>(epochs_run);
    staged[result_length++] = converged ? 1.0 : 0.0;
    staged[result_length++] = static_cast<double>(query_count);
    for (std::size_t row = 0; row < query_count; ++row) {
        double weighted_sum = bias;
        for (std::size_t feature = 0; feature < feature_count; ++feature) {
            weighted_sum += weights[feature] * input[query_start + row * feature_count + feature];
        }
        staged[result_length++] = weighted_sum >= 0.0 ? 1.0 : 0.0;
    }

    if (output == nullptr || output_capacity < result_length) return -2;
    for (std::size_t index = 0; index < result_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(result_length);
}
