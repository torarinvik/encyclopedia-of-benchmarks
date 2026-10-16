#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_SAMPLES 32
#define MAX_FEATURES 8
#define Q_SCALE 1000000.0

static void put_f64(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t logistic_regression_python_binary_gd(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4) return -1;
    int64_t m_value = input[0], d_value = input[1], epochs_value = input[2], alpha_q = input[3];
    if (m_value < 1 || m_value > MAX_SAMPLES || d_value < 1 || d_value > MAX_FEATURES
            || epochs_value < 0 || epochs_value > 128 || alpha_q < 1 || alpha_q > 100000) return -1;
    int m = (int)m_value, d = (int)d_value, epochs = (int)epochs_value;
    if (length != 4 + (size_t)m * (size_t)d + (size_t)m) return -1;
    size_t labels_offset = 4 + (size_t)m * (size_t)d;
    for (size_t i = 0; i < (size_t)m * (size_t)d; ++i)
        if (input[4 + i] < -1000000 || input[4 + i] > 1000000) return -1;
    for (int sample = 0; sample < m; ++sample)
        if (input[labels_offset + (size_t)sample] != 0 && input[labels_offset + (size_t)sample] != 1) return -1;
    size_t required = (size_t)d * 8;
    if (output == NULL || capacity < required) return -2;

    double theta[MAX_FEATURES] = {0.0}, next_theta[MAX_FEATURES], errors[MAX_SAMPLES];
    double alpha = (double)alpha_q / Q_SCALE;
    for (int epoch = 0; epoch < epochs; ++epoch) {
        for (int sample = 0; sample < m; ++sample) {
            double score = 0.0;
            for (int feature = 0; feature < d; ++feature) {
                double x = (double)input[4 + sample * d + feature] / Q_SCALE;
                score += x * theta[feature];
            }
            double prediction = 1.0 / (1.0 + exp(-score));
            errors[sample] = prediction - (double)input[labels_offset + (size_t)sample];
        }
        for (int feature = 0; feature < d; ++feature) {
            double gradient = 0.0;
            for (int sample = 0; sample < m; ++sample) {
                double x = (double)input[4 + sample * d + feature] / Q_SCALE;
                gradient += x * errors[sample];
            }
            gradient /= (double)m;
            next_theta[feature] = theta[feature] - alpha * gradient;
        }
        for (int feature = 0; feature < d; ++feature) theta[feature] = next_theta[feature];
    }
    for (int feature = 0; feature < d; ++feature) put_f64(output, (size_t)feature * 8, theta[feature]);
    return (int64_t)required;
}
