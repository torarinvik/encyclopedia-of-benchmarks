#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PATTERN_COUNT 10
#define MAX_NEURONS 8
#define MAX_INPUT_LENGTH 94
#define MAX_DELTA_PASSES 1

static float activation(float value) {
    double x = (double)value;
    if (x > 200.0) x = 200.0;
    if (x < -200.0) x = -200.0;
    const double e = exp(-x);
    return (float)((1.0 - e) / (1.0 + e));
}

static int run_cont(const float *weights, const int64_t *source, size_t neurons, int64_t *dest) {
    float temp_a[MAX_NEURONS];
    int64_t temp_c[MAX_NEURONS];
    for (size_t neuron = 0; neuron < neurons; ++neuron) temp_a[neuron] = (float)(dest[neuron] = source[neuron]);
    int stable = 0, threshold = 0, iterations = 0;
    while (!stable && iterations < 500) {
        int threshold_iterations = 0;
        for (size_t row = 0; row < neurons; ++row) {
            float sum = 0.0f;
            for (size_t neuron = 0; neuron < neurons; ++neuron)
                sum += weights[row * neurons + neuron] * (float)source[neuron];
            temp_a[row] = activation(sum);
        }
        while (!threshold && threshold_iterations < 50) {
            threshold = 1;
            for (size_t row = 0; row < neurons; ++row) {
                if (fabs((double)temp_a[row]) < 0.7) {
                    float sum = 0.0f;
                    for (size_t neuron = 0; neuron < neurons; ++neuron)
                        sum += weights[row * neurons + neuron] * temp_a[neuron];
                    temp_a[row] = activation(sum);
                    if (temp_a[row] < 0.7f) threshold = 0;
                }
            }
            ++threshold_iterations;
        }
        int same = 1;
        for (size_t neuron = 0; neuron < neurons; ++neuron) {
            temp_c[neuron] = temp_a[neuron] > 0.0f ? 1 : -1;
            if (dest[neuron] != temp_c[neuron]) same = 0;
        }
        if (same) stable = 1;
        else {
            for (size_t neuron = 0; neuron < neurons; ++neuron) {
                if (dest[neuron] != temp_c[neuron]) {
                    dest[neuron] = temp_c[neuron];
                    break;
                }
            }
            for (size_t neuron = 0; neuron < neurons; ++neuron) temp_a[neuron] = (float)dest[neuron];
        }
        ++iterations;
    }
    return iterations == 500 ? -1 : iterations;
}

int64_t freebench_neural_hopfield(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t width = input[0], height = input[1], pattern_count = input[2];
    if (width < 1 || width > 8 || height < 1 || height > 8 || pattern_count != PATTERN_COUNT) return -1;
    const size_t neurons = (size_t)(width * height);
    if (neurons < 2 || neurons > MAX_NEURONS || length != 3 + PATTERN_COUNT * (1 + neurons)) return -1;

    int64_t patterns[PATTERN_COUNT][MAX_NEURONS];
    size_t offset = 3;
    for (size_t pattern = 0; pattern < PATTERN_COUNT; ++pattern) {
        const int64_t label = input[offset++];
        if (label < 65 || label > 90) return -1;
        for (size_t neuron = 0; neuron < neurons; ++neuron) {
            const int64_t cell = input[offset++];
            if (cell != -1 && cell != 1) return -1;
            patterns[pattern][neuron] = cell;
            if (pattern != 0 && cell != patterns[0][neuron]) return -1;
        }
    }

    int hamming_warnings = 0;
    for (size_t first = 0; first < PATTERN_COUNT; ++first) {
        for (size_t second = first + 1; second < PATTERN_COUNT; ++second) {
            int normal = 0, complement = 0;
            for (size_t neuron = 0; neuron < neurons; ++neuron) {
                if (patterns[first][neuron] != patterns[second][neuron]) ++normal;
                if (patterns[first][neuron] != -patterns[second][neuron]) ++complement;
            }
            if (normal < 2) ++hamming_warnings;
            if (complement < 2) ++hamming_warnings;
        }
    }
    (void)hamming_warnings;

    float weights[MAX_NEURONS * MAX_NEURONS] = {0};
    for (size_t pattern = 0; pattern < PATTERN_COUNT; ++pattern) {
        for (size_t row = 0; row < neurons; ++row) {
            for (size_t column = 0; column < neurons; ++column) {
                if (row == column) weights[row * neurons + column] = 0.0f;
                else weights[row * neurons + column] += (float)(patterns[pattern][row] * patterns[pattern][column]);
            }
        }
    }

    int converged = 0;
    for (size_t pass = 0; pass < MAX_DELTA_PASSES; ++pass) {
        int status = 1;
        for (size_t pattern = 0; pattern < PATTERN_COUNT; ++pattern) {
            int64_t recalled[MAX_NEURONS];
            if (run_cont(weights, patterns[pattern], neurons, recalled) < 0) return -2;
            float correction[MAX_NEURONS];
            for (size_t neuron = 0; neuron < neurons; ++neuron) {
                correction[neuron] = (float)(patterns[pattern][neuron] - recalled[neuron]) * 0.5f;
                if (correction[neuron] != 0.0f) status = 0;
            }
            for (size_t row = 0; row < neurons; ++row) {
                for (size_t column = 0; column < neurons; ++column) {
                    if (row == column) weights[row * neurons + column] = 0.0f;
                    else weights[row * neurons + column] += correction[row] * (float)patterns[pattern][column];
                }
            }
        }
        if (status) { converged = 1; break; }
    }
    if (!converged) return -2;

    int64_t stored_count = 0;
    for (size_t pattern = 0; pattern < PATTERN_COUNT; ++pattern) {
        int64_t recalled[MAX_NEURONS];
        if (run_cont(weights, patterns[pattern], neurons, recalled) < 0) return -2;
        int stored = 1;
        for (size_t neuron = 0; neuron < neurons; ++neuron)
            if (patterns[pattern][neuron] != recalled[neuron]) stored = 0;
        if (stored) ++stored_count;
    }
    return stored_count;
}
