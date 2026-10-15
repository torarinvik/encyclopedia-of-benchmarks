module adam;

const usz MAX_STEPS = 256;
const usz MAX_PARAMETERS = 16;
const double INPUT_SCALE = 1000000000.0;
const double OUTPUT_SCALE = 1000000.0;

fn double adam_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (usz iteration = 0; iteration < 80; iteration++) root = 0.5 * (root + value / root);
    return root;
}

fn long adam(long* input, usz length, char* output, usz output_capacity)
    @export("adam") {
    const usz MAX_INPUT_LENGTH = 7 + MAX_PARAMETERS + MAX_STEPS * MAX_PARAMETERS;
    if (input == null || length < 9 || length > MAX_INPUT_LENGTH) return -1;
    long steps_value = input[0];
    long parameter_count_value = input[1];
    long learning_rate_value = input[2];
    long beta1_value = input[3];
    long beta2_value = input[4];
    long epsilon_value = input[5];
    long weight_decay_value = input[6];
    if (steps_value < 1 || steps_value > (long)MAX_STEPS || parameter_count_value < 1 ||
        parameter_count_value > (long)MAX_PARAMETERS) return -1;
    usz steps = (usz)steps_value;
    usz parameter_count = (usz)parameter_count_value;
    if (length != 7 + parameter_count + steps * parameter_count ||
        learning_rate_value < 1 || learning_rate_value > 1000000000 ||
        beta1_value < 0 || beta1_value >= 1000000000 || beta2_value < 0 || beta2_value >= 1000000000 ||
        epsilon_value < 1 || epsilon_value > 10000000 || weight_decay_value < 0 || weight_decay_value > 100000000) return -1;
    for (usz i = 0; i < parameter_count; i++) {
        if (input[7 + i] < -1000000000000000L || input[7 + i] > 1000000000000000L) return -1;
    }
    usz gradient_start = 7 + parameter_count;
    for (usz i = 0; i < steps * parameter_count; i++) {
        if (input[gradient_start + i] < -1000000000000L || input[gradient_start + i] > 1000000000000L) return -1;
    }
    usz output_count = steps * parameter_count;
    if (output == null || output_capacity < 8 * output_count) return -2;

    double learning_rate = (double)learning_rate_value / INPUT_SCALE;
    double beta1 = (double)beta1_value / INPUT_SCALE;
    double beta2 = (double)beta2_value / INPUT_SCALE;
    double epsilon = (double)epsilon_value / INPUT_SCALE;
    double weight_decay = (double)weight_decay_value / INPUT_SCALE;
    double[MAX_PARAMETERS] parameters = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    double[MAX_PARAMETERS] first_moment = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    double[MAX_PARAMETERS] second_moment = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};
    for (usz i = 0; i < parameter_count; i++) parameters[i] = (double)input[7 + i] / INPUT_SCALE;
    double beta1_power = 1.0;
    double beta2_power = 1.0;
    for (usz step = 0; step < steps; step++) {
        beta1_power *= beta1;
        beta2_power *= beta2;
        for (usz i = 0; i < parameter_count; i++) {
            double gradient = (double)input[gradient_start + step * parameter_count + i] / INPUT_SCALE;
            first_moment[i] = beta1 * first_moment[i] + (1.0 - beta1) * gradient;
            second_moment[i] = beta2 * second_moment[i] + (1.0 - beta2) * (gradient * gradient);
            double corrected_first = first_moment[i] / (1.0 - beta1_power);
            double corrected_second = second_moment[i] / (1.0 - beta2_power);
            double updated = parameters[i] - learning_rate * corrected_first /
                (adam_sqrt(corrected_second) + epsilon) - learning_rate * weight_decay * parameters[i];
            parameters[i] = updated;
            long encoded = (long)(updated * OUTPUT_SCALE);
            usz output_index = step * parameter_count + i;
            for (usz byte = 0; byte < 8; byte++) output[8 * output_index + byte] = (char)((encoded >> (byte * 8)) & 255);
        }
    }
    return (long)output_count;
}
