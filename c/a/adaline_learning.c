/* Fixed-point projection of the pinned deterministic ADALINE update loop. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 32
#define MAX_FEATURES 8

static void store_i32_le(int64_t value, uint8_t *output, size_t offset) {
    uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t adaline_learning(const int64_t *input, size_t length,
                         uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 5) return -1;
    if (input[0] < 1 || input[0] > MAX_SAMPLES ||
        input[1] < 1 || input[1] > MAX_FEATURES ||
        input[2] < 1 || input[3] < 1 || input[3] > 12 ||
        input[4] < 1 || input[4] > 500) return -1;

    size_t sample_count = (size_t)input[0];
    size_t feature_count = (size_t)input[1];
    int64_t eta_numerator = input[2];
    size_t eta_shift = (size_t)input[3];
    size_t max_iterations = (size_t)input[4];
    int64_t scale = INT64_C(1) << eta_shift;
    if (eta_numerator >= scale || length != 5 + sample_count * (feature_count + 1))
        return -1;

    for (size_t sample = 0; sample < sample_count; ++sample) {
        size_t row = 5 + sample * (feature_count + 1);
        for (size_t feature = 0; feature < feature_count; ++feature)
            if (input[row + feature] < -16 || input[row + feature] > 16) return -1;
        int64_t label = input[row + feature_count];
        if (label != -1 && label != 1) return -1;
    }

    size_t bytes = 4 * (1 + feature_count + 1 + sample_count);
    if (output_capacity < bytes || output == NULL) return -2;

    int64_t weights[MAX_FEATURES] = {0};
    for (size_t feature = 0; feature < feature_count; ++feature) weights[feature] = scale;
    int64_t bias = scale;
    size_t iterations = 0;
    for (; iterations < max_iterations; ++iterations) {
        size_t mistakes = 0;
        for (size_t sample = 0; sample < sample_count; ++sample) {
            size_t row = 5 + sample * (feature_count + 1);
            int64_t score = bias;
            for (size_t feature = 0; feature < feature_count; ++feature)
                score += input[row + feature] * weights[feature];
            int64_t prediction = score > 0 ? 1 : -1;
            int64_t error = input[row + feature_count] - prediction;
            if (error != 0) {
                ++mistakes;
                int64_t correction = eta_numerator * error;
                for (size_t feature = 0; feature < feature_count; ++feature)
                    weights[feature] += correction * input[row + feature];
                bias += correction;
            }
        }
        if (mistakes == 0) {
            ++iterations;
            break;
        }
    }

    size_t position = 0;
    store_i32_le((int64_t)iterations, output, position); position += 4;
    for (size_t feature = 0; feature < feature_count; ++feature, position += 4)
        store_i32_le(weights[feature], output, position);
    store_i32_le(bias, output, position); position += 4;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        size_t row = 5 + sample * (feature_count + 1);
        int64_t score = bias;
        for (size_t feature = 0; feature < feature_count; ++feature)
            score += input[row + feature] * weights[feature];
        store_i32_le(score > 0 ? 1 : -1, output, position);
        position += 4;
    }
    return (int64_t)bytes;
}
