#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_CLASSES 4u
#define MAX_SAMPLES 16u
#define MAX_INPUT 22u
#define MIN_MARGIN 1e-8

int64_t linear_discriminant_analysis(const double *input, size_t input_length,
                                    double *output, size_t capacity) {
    if (input == NULL || input_length == 0u || input_length > MAX_INPUT) return -1;
    const double class_value = input[0];
    if (!isfinite(class_value) || class_value < 2.0 || class_value > 4.0 || trunc(class_value) != class_value) return -1;
    const size_t class_count = (size_t)class_value;
    if (input_length < 1u + class_count) return -1;
    size_t counts[MAX_CLASSES] = {0}, total_count = 0;
    for (size_t k = 0; k < class_count; ++k) {
        const double value = input[1u + k];
        if (!isfinite(value) || value < 2.0 || value > 6.0 || trunc(value) != value) return -1;
        counts[k] = (size_t)value;
        total_count += counts[k];
    }
    if (total_count > MAX_SAMPLES || input_length != 1u + class_count + total_count) return -1;

    double groups[MAX_CLASSES][6] = {{0.0}}, means[MAX_CLASSES] = {0.0};
    size_t offset = 1u + class_count;
    for (size_t k = 0; k < class_count; ++k) {
        double sum = 0.0;
        for (size_t j = 0; j < counts[k]; ++j) {
            const double x = input[offset++];
            if (!isfinite(x) || x < -32.0 || x > 32.0 || trunc(x) != x) return -1;
            groups[k][j] = x;
            sum += x;
        }
        means[k] = sum / (double)counts[k];
        if (trunc(means[k]) != means[k]) return -1;
    }

    double squared_sum = 0.0;
    for (size_t k = 0; k < class_count; ++k)
        for (size_t j = 0; j < counts[k]; ++j) {
            const double delta = groups[k][j] - means[k];
            squared_sum += delta * delta;
        }
    const double variance = (1.0 / (double)(total_count - class_count)) * squared_sum;
    if (!isfinite(variance) || variance <= 0.0) return -1;
    double priors[MAX_CLASSES];
    for (size_t k = 0; k < class_count; ++k) priors[k] = (double)counts[k] / (double)total_count;

    double staged[MAX_SAMPLES];
    size_t n = 0;
    for (size_t group = 0; group < class_count; ++group) {
        for (size_t j = 0; j < counts[group]; ++j) {
            const double x = groups[group][j];
            double best = -INFINITY, second = -INFINITY;
            size_t winner = 0;
            for (size_t k = 0; k < class_count; ++k) {
                const double score = x * (means[k] / variance)
                    - (means[k] * means[k] / (2.0 * variance)) + log(priors[k]);
                if (score > best) { second = best; best = score; winner = k; }
                else if (score > second) second = score;
            }
            if (!isfinite(best) || best - second < MIN_MARGIN) return -1;
            staged[n++] = (double)winner;
        }
    }
    if (output == NULL || capacity < n) return -2;
    for (size_t i = 0; i < n; ++i) output[i] = staged[i];
    return (int64_t)n;
}
