#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxParseableInputLength = 45;
constexpr std::size_t kMaxSamples = 8;
constexpr std::size_t kMaxFeatures = 4;
constexpr std::size_t kMaxFeatureValues = kMaxSamples * kMaxFeatures;
}

extern "C" std::int64_t linear_regression_vectorized(
    const double *input, std::size_t length, double *output,
    std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 4 || length > kMaxParseableInputLength) return -1;
    const double sample_value = input[0], feature_value = input[1], iteration_value = input[2];
    if (sample_value != sample_value || sample_value < 2.0 || sample_value > kMaxSamples ||
        feature_value != feature_value || feature_value < 2.0 || feature_value > kMaxFeatures ||
        iteration_value != iteration_value || iteration_value < 10.0 || iteration_value > 128.0) return -1;
    const auto sample_count = static_cast<std::size_t>(sample_value);
    const auto feature_count = static_cast<std::size_t>(feature_value);
    const auto iterations = static_cast<std::size_t>(iteration_value);
    if (static_cast<double>(sample_count) != sample_value ||
        static_cast<double>(feature_count) != feature_value ||
        static_cast<double>(iterations) != iteration_value) return -1;
    if (length != 4 + sample_count * feature_count + sample_count) return -1;

    const double alpha = input[3];
    if (alpha != alpha || alpha < 0.0001 || alpha > 0.01) return -1;

    double features[kMaxFeatureValues];
    double labels[kMaxSamples];
    const std::size_t feature_values = sample_count * feature_count;
    for (std::size_t index = 0; index < feature_values; ++index) {
        const double value = input[4 + index];
        if (value != value || value < -1.0 || value > 1.0) return -1;
        features[index] = value;
    }
    for (std::size_t row = 0; row < sample_count; ++row)
        if (features[row * feature_count] != 1.0) return -1;
    for (std::size_t row = 0; row < sample_count; ++row) {
        const double value = input[4 + feature_values + row];
        if (value != value || value < -1.0 || value > 1.0) return -1;
        labels[row] = value;
    }
    if (output == nullptr || output_capacity < feature_count) return -2;

    double theta[kMaxFeatures] = {};
    double errors[kMaxSamples];
    double gradients[kMaxFeatures];
    for (std::size_t iteration = 0; iteration < iterations; ++iteration) {
        for (std::size_t row = 0; row < sample_count; ++row) {
            double prediction = 0.0;
            for (std::size_t column = 0; column < feature_count; ++column)
                prediction += features[row * feature_count + column] * theta[column];
            errors[row] = prediction - labels[row];
        }
        for (std::size_t column = 0; column < feature_count; ++column) {
            double gradient = 0.0;
            for (std::size_t row = 0; row < sample_count; ++row)
                gradient += features[row * feature_count + column] * errors[row];
            gradients[column] = gradient / static_cast<double>(sample_count);
        }
        for (std::size_t column = 0; column < feature_count; ++column)
            theta[column] -= alpha * gradients[column];
    }
    for (std::size_t column = 0; column < feature_count; ++column) output[column] = theta[column];
    return static_cast<std::int64_t>(feature_count);
}
