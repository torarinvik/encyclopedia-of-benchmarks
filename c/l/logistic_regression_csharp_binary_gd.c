#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 32
#define MAX_FEATURES 8
#define Q_SCALE 1000000.0
#define INVALID_RESULT (-1.0e300)

double logistic_regression_csharp_binary_gd(const int64_t *input, size_t length) {
    if (input == NULL || length < 4) return INVALID_RESULT;
    int64_t m_value = input[0], d_value = input[1], epochs_value = input[2], rate_q = input[3];
    if (m_value < 1 || m_value > MAX_SAMPLES || d_value < 1 || d_value > MAX_FEATURES ||
        epochs_value < 0 || epochs_value > 128 || rate_q < 1 || rate_q > 100000) return INVALID_RESULT;
    const int m = (int)m_value, d = (int)d_value, epochs = (int)epochs_value;
    const size_t feature_count = (size_t)m * (size_t)d;
    const size_t labels_offset = 4 + feature_count;
    const size_t query_offset = labels_offset + (size_t)m;
    if (length != query_offset + (size_t)d) return INVALID_RESULT;
    for (size_t i = 0; i < feature_count; ++i)
        if (input[4 + i] < -1000000 || input[4 + i] > 1000000) return INVALID_RESULT;
    for (int sample = 0; sample < m; ++sample)
        if (input[labels_offset + (size_t)sample] != 0 && input[labels_offset + (size_t)sample] != 1) return INVALID_RESULT;
    for (int feature = 0; feature < d; ++feature)
        if (input[query_offset + (size_t)feature] < -1000000 || input[query_offset + (size_t)feature] > 1000000) return INVALID_RESULT;

    double weights[MAX_FEATURES] = {0.0}, next_weights[MAX_FEATURES], errors[MAX_SAMPLES];
    double bias = 0.0;
    const double learning_rate = (double)rate_q / Q_SCALE;
    for (int epoch = 0; epoch < epochs; ++epoch) {
        double bias_gradient = 0.0;
        for (int sample = 0; sample < m; ++sample) {
            double dot = 0.0;
            for (int feature = 0; feature < d; ++feature) {
                double x = (double)input[4 + (size_t)sample * (size_t)d + (size_t)feature] / Q_SCALE;
                dot += x * weights[feature];
            }
            double linear = dot + bias;
            double prediction = 1.0 / (1.0 + exp(-linear));
            errors[sample] = prediction - (double)input[labels_offset + (size_t)sample];
            bias_gradient += errors[sample];
        }
        for (int feature = 0; feature < d; ++feature) {
            double gradient = 0.0;
            for (int sample = 0; sample < m; ++sample) {
                double x = (double)input[4 + (size_t)sample * (size_t)d + (size_t)feature] / Q_SCALE;
                gradient += errors[sample] * x;
            }
            next_weights[feature] = weights[feature] - learning_rate * gradient / (double)m;
        }
        for (int feature = 0; feature < d; ++feature) weights[feature] = next_weights[feature];
        bias -= learning_rate * bias_gradient / (double)m;
    }
    double query_dot = 0.0;
    for (int feature = 0; feature < d; ++feature) {
        double x = (double)input[query_offset + (size_t)feature] / Q_SCALE;
        query_dot += x * weights[feature];
    }
    double query_score = query_dot + bias;
    return 1.0 / (1.0 + exp(-query_score));
}
