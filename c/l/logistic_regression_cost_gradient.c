#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_SAMPLES 64
#define MAX_FEATURES 8
#define Q_SCALE 1000000.0

static void put_f64(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t logistic_regression_cost_gradient(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    const int64_t m_value = input[0], d_value = input[1];
    if (m_value < 1 || m_value > MAX_SAMPLES || d_value < 1 || d_value > MAX_FEATURES) return -1;
    const size_t m = (size_t)m_value, d = (size_t)d_value;
    const size_t features_offset = 2;
    const size_t theta_offset = features_offset + m * d;
    const size_t labels_offset = theta_offset + d;
    if (length != labels_offset + m) return -1;
    for (size_t index = 0; index < m * d; ++index)
        if (input[features_offset + index] < -1000000 || input[features_offset + index] > 1000000) return -1;
    for (size_t feature = 0; feature < d; ++feature)
        if (input[theta_offset + feature] < -1000000 || input[theta_offset + feature] > 1000000) return -1;
    for (size_t sample = 0; sample < m; ++sample)
        if (input[labels_offset + sample] != 0 && input[labels_offset + sample] != 1) return -1;

    const size_t required = (d + 1) * 8;
    if (output == NULL || capacity < required) return -2;

    double loss = 0.0;
    double gradient[MAX_FEATURES] = {0.0};
    for (size_t sample = 0; sample < m; ++sample) {
        double score = 0.0;
        for (size_t feature = 0; feature < d; ++feature) {
            const double x = (double)input[features_offset + sample * d + feature] / Q_SCALE;
            const double theta = (double)input[theta_offset + feature] / Q_SCALE;
            score += x * theta;
        }
        const double probability = 1.0 / (1.0 + exp(-score));
        const double label = (double)input[labels_offset + sample];
        loss += -label * log(probability) - (1.0 - label) * log(1.0 - probability);
        const double error = probability - label;
        for (size_t feature = 0; feature < d; ++feature) {
            const double x = (double)input[features_offset + sample * d + feature] / Q_SCALE;
            gradient[feature] += error * x;
        }
    }
    put_f64(output, 0, loss / (double)m);
    for (size_t feature = 0; feature < d; ++feature)
        put_f64(output, (feature + 1) * 8, gradient[feature] / (double)m);
    return (int64_t)required;
}
