#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_samples = 32;
constexpr int max_features = 8;
constexpr double q_scale = 1'000'000.0;
constexpr double invalid_result = -1.0e300;
}

extern "C" double logistic_regression_csharp_binary_gd(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4) return invalid_result;
    const auto mv = input[0], dv = input[1], epochs_value = input[2], rate_q = input[3];
    if (mv < 1 || mv > max_samples || dv < 1 || dv > max_features ||
        epochs_value < 0 || epochs_value > 128 || rate_q < 1 || rate_q > 100000) return invalid_result;
    const int m = static_cast<int>(mv), d = static_cast<int>(dv), epochs = static_cast<int>(epochs_value);
    const std::size_t feature_count = static_cast<std::size_t>(m) * static_cast<std::size_t>(d);
    const std::size_t labels_offset = 4 + feature_count;
    const std::size_t query_offset = labels_offset + static_cast<std::size_t>(m);
    if (length != query_offset + static_cast<std::size_t>(d)) return invalid_result;
    for (std::size_t i = 0; i < feature_count; ++i)
        if (input[4 + i] < -1'000'000 || input[4 + i] > 1'000'000) return invalid_result;
    for (int sample = 0; sample < m; ++sample)
        if (input[labels_offset + static_cast<std::size_t>(sample)] != 0 &&
            input[labels_offset + static_cast<std::size_t>(sample)] != 1) return invalid_result;
    for (int feature = 0; feature < d; ++feature)
        if (input[query_offset + static_cast<std::size_t>(feature)] < -1'000'000 ||
            input[query_offset + static_cast<std::size_t>(feature)] > 1'000'000) return invalid_result;

    double weights[max_features]{}, next_weights[max_features], errors[max_samples];
    double bias = 0.0;
    const double learning_rate = static_cast<double>(rate_q) / q_scale;
    for (int epoch = 0; epoch < epochs; ++epoch) {
        double bias_gradient = 0.0;
        for (int sample = 0; sample < m; ++sample) {
            double dot = 0.0;
            for (int feature = 0; feature < d; ++feature) {
                const double x = static_cast<double>(input[4 + static_cast<std::size_t>(sample) * d + feature]) / q_scale;
                dot += x * weights[feature];
            }
            const double linear = dot + bias;
            const double prediction = 1.0 / (1.0 + std::exp(-linear));
            errors[sample] = prediction - static_cast<double>(input[labels_offset + static_cast<std::size_t>(sample)]);
            bias_gradient += errors[sample];
        }
        for (int feature = 0; feature < d; ++feature) {
            double gradient = 0.0;
            for (int sample = 0; sample < m; ++sample) {
                const double x = static_cast<double>(input[4 + static_cast<std::size_t>(sample) * d + feature]) / q_scale;
                gradient += errors[sample] * x;
            }
            next_weights[feature] = weights[feature] - learning_rate * gradient / static_cast<double>(m);
        }
        for (int feature = 0; feature < d; ++feature) weights[feature] = next_weights[feature];
        bias -= learning_rate * bias_gradient / static_cast<double>(m);
    }
    double query_dot = 0.0;
    for (int feature = 0; feature < d; ++feature) {
        const double x = static_cast<double>(input[query_offset + static_cast<std::size_t>(feature)]) / q_scale;
        query_dot += x * weights[feature];
    }
    const double query_score = query_dot + bias;
    return 1.0 / (1.0 + std::exp(-query_score));
}
