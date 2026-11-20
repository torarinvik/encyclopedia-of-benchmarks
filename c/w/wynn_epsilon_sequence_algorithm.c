#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 10u
#define MAX_INPUT_LENGTH 13u
#define MAX_OUTPUT_ELEMENTS 36u

int64_t wynn_epsilon_sequence_algorithm(const double *input, size_t input_length,
                                         double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 3 || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i) if (!isfinite(input[i])) return -1;
    const double n_value = input[0], k_value = input[1];
    if (floor(n_value) != n_value || floor(k_value) != k_value
        || n_value < 5.0 || n_value > (double)MAX_N
        || k_value < 2.0 || k_value > 3.0) return -1;
    const size_t n = (size_t)n_value, k = (size_t)k_value;
    if (n < 2 * k + 1 || input_length != n + 2) return -1;
    for (size_t i = 0; i < n; ++i) {
        const double sample = input[i + 2];
        const double scaled = sample * 256.0;
        if (sample < -2.0 || sample > 2.0 || floor(scaled) != scaled) return -1;
    }

    double rows[2 * 3 + 1][MAX_N] = {{0.0}};
    bool valid[2 * 3 + 1][MAX_N] = {{false}};
    for (size_t i = 0; i < n; ++i) {
        rows[0][i] = input[i + 2];
        valid[0][i] = true;
    }
    for (size_t order = 0; order < 2 * k; ++order) {
        const size_t width = n - order - 1;
        for (size_t i = 0; i < width; ++i) {
            const bool auxiliary_valid = order == 0 || valid[order - 1][i + 1];
            if (!valid[order][i] || !valid[order][i + 1] || !auxiliary_valid) continue;
            const double denominator = rows[order][i + 1] - rows[order][i];
            if (denominator == 0.0 || !isfinite(denominator)) continue;
            const double reciprocal = 1.0 / denominator;
            const double auxiliary = order == 0 ? 0.0 : rows[order - 1][i + 1];
            const double value = auxiliary + reciprocal;
            if (!isfinite(reciprocal) || !isfinite(value)) continue;
            rows[order + 1][i] = value;
            valid[order + 1][i] = true;
        }
    }

    size_t needed = 0;
    for (size_t order = 2; order <= 2 * k; order += 2) needed += 2 * (n - order);
    if (output == NULL || output_capacity < needed) return -2;
    size_t cursor = 0;
    for (size_t order = 2; order <= 2 * k; order += 2) {
        for (size_t i = 0; i < n - order; ++i) {
            output[cursor++] = valid[order][i] ? 0.0 : 1.0;
            output[cursor++] = valid[order][i] ? rows[order][i] : 0.0;
        }
    }
    return (int64_t)needed;
}
