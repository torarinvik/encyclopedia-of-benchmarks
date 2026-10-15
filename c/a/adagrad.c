#include <stddef.h>
#include <stdint.h>

#define MAX_STEPS 256
#define MAX_GROUPS 16
#define INPUT_SCALE 1000000000.0
#define OUTPUT_SCALE 1000000.0

static double adagrad_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (int iteration = 0; iteration < 80; ++iteration) root = 0.5 * (root + value / root);
    return root;
}

int64_t adagrad(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 6 || length > 3 + 3 * MAX_STEPS) return -1;
    const int64_t steps_value = input[0], learning_rate_value = input[1], epsilon_value = input[2];
    if (steps_value < 1 || steps_value > MAX_STEPS || length != 3 + 3 * (size_t)steps_value ||
        learning_rate_value < 1 || learning_rate_value > 1000000000 ||
        epsilon_value < 1 || epsilon_value > 10000000) return -1;
    const size_t steps = (size_t)steps_value;
    for (size_t step = 0; step < steps; ++step) {
        const int64_t id = input[3 + 3 * step], parameter = input[4 + 3 * step], gradient = input[5 + 3 * step];
        if (id < 0 || id >= MAX_GROUPS || parameter < -1000000000000000LL || parameter > 1000000000000000LL ||
            gradient < -1000000000000LL || gradient > 1000000000000LL) return -1;
    }
    if (output == NULL || output_capacity < 8 * steps) return -2;

    const double learning_rate = (double)learning_rate_value / INPUT_SCALE;
    const double epsilon = (double)epsilon_value / INPUT_SCALE;
    double accumulated[MAX_GROUPS] = {0.0};
    for (size_t step = 0; step < steps; ++step) {
        const size_t id = (size_t)input[3 + 3 * step];
        const double parameter = (double)input[4 + 3 * step] / INPUT_SCALE;
        const double gradient = (double)input[5 + 3 * step] / INPUT_SCALE;
        accumulated[id] += gradient * gradient;
        const double updated = parameter - learning_rate / (adagrad_sqrt(accumulated[id]) + epsilon) * gradient;
        const int64_t encoded = (int64_t)(updated * OUTPUT_SCALE);
        const uint64_t bits = (uint64_t)encoded;
        for (size_t byte = 0; byte < 8; ++byte) output[8 * step + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)steps;
}
