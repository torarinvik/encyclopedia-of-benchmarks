#include <stddef.h>
#include <stdint.h>

#define MAX_STEPS 256
#define MAX_PARAMETERS 16
#define INPUT_SCALE 1000000000.0
#define OUTPUT_SCALE 1000000.0

static double adam_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (int iteration = 0; iteration < 80; ++iteration) root = 0.5 * (root + value / root);
    return root;
}

int64_t adam(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    const size_t max_input_length = 7 + MAX_PARAMETERS + MAX_STEPS * MAX_PARAMETERS;
    if (input == NULL || length < 9 || length > max_input_length) return -1;
    const int64_t steps_value = input[0], parameter_count_value = input[1];
    const int64_t learning_rate_value = input[2], beta1_value = input[3], beta2_value = input[4];
    const int64_t epsilon_value = input[5], weight_decay_value = input[6];
    if (steps_value < 1 || steps_value > MAX_STEPS || parameter_count_value < 1 ||
        parameter_count_value > MAX_PARAMETERS) return -1;
    const size_t steps = (size_t)steps_value, parameter_count = (size_t)parameter_count_value;
    if (length != 7 + parameter_count + steps * parameter_count ||
        learning_rate_value < 1 || learning_rate_value > 1000000000 ||
        beta1_value < 0 || beta1_value >= 1000000000 ||
        beta2_value < 0 || beta2_value >= 1000000000 ||
        epsilon_value < 1 || epsilon_value > 10000000 ||
        weight_decay_value < 0 || weight_decay_value > 100000000) return -1;
    for (size_t i = 0; i < parameter_count; ++i)
        if (input[7 + i] < -1000000000000000LL || input[7 + i] > 1000000000000000LL) return -1;
    const size_t gradient_start = 7 + parameter_count;
    for (size_t i = 0; i < steps * parameter_count; ++i)
        if (input[gradient_start + i] < -1000000000000LL || input[gradient_start + i] > 1000000000000LL) return -1;
    const size_t output_count = steps * parameter_count;
    if (output == NULL || output_capacity < 8 * output_count) return -2;

    const double learning_rate = (double)learning_rate_value / INPUT_SCALE;
    const double beta1 = (double)beta1_value / INPUT_SCALE;
    const double beta2 = (double)beta2_value / INPUT_SCALE;
    const double epsilon = (double)epsilon_value / INPUT_SCALE;
    const double weight_decay = (double)weight_decay_value / INPUT_SCALE;
    double parameters[MAX_PARAMETERS], first_moment[MAX_PARAMETERS] = {0.0};
    double second_moment[MAX_PARAMETERS] = {0.0};
    for (size_t i = 0; i < parameter_count; ++i) parameters[i] = (double)input[7 + i] / INPUT_SCALE;
    double beta1_power = 1.0, beta2_power = 1.0;
    for (size_t step = 0; step < steps; ++step) {
        beta1_power *= beta1;
        beta2_power *= beta2;
        for (size_t i = 0; i < parameter_count; ++i) {
            const double gradient = (double)input[gradient_start + step * parameter_count + i] / INPUT_SCALE;
            first_moment[i] = beta1 * first_moment[i] + (1.0 - beta1) * gradient;
            second_moment[i] = beta2 * second_moment[i] + (1.0 - beta2) * (gradient * gradient);
            const double corrected_first = first_moment[i] / (1.0 - beta1_power);
            const double corrected_second = second_moment[i] / (1.0 - beta2_power);
            const double updated = parameters[i] - learning_rate * corrected_first /
                (adam_sqrt(corrected_second) + epsilon) - learning_rate * weight_decay * parameters[i];
            parameters[i] = updated;
            const int64_t encoded = (int64_t)(updated * OUTPUT_SCALE);
            const uint64_t bits = (uint64_t)encoded;
            const size_t output_index = step * parameter_count + i;
            for (size_t byte = 0; byte < 8; ++byte)
                output[8 * output_index + byte] = (uint8_t)(bits >> (8 * byte));
        }
    }
    return (int64_t)output_count;
}
