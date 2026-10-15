module adagrad;

const usz MAX_STEPS = 256;
const usz MAX_GROUPS = 16;
const double INPUT_SCALE = 1000000000.0;
const double OUTPUT_SCALE = 1000000.0;

fn double adagrad_sqrt(double value) {
    if (value <= 0.0) return 0.0;
    double root = value > 1.0 ? value : 1.0;
    for (usz iteration = 0; iteration < 80; iteration++) root = 0.5 * (root + value / root);
    return root;
}

fn long adagrad(long* input, usz length, char* output, usz output_capacity)
    @export("adagrad") {
    if (input == null || length < 6 || length > 3 + 3 * MAX_STEPS) return -1;
    long steps_value = input[0];
    long learning_rate_value = input[1];
    long epsilon_value = input[2];
    if (steps_value < 1 || steps_value > (long)MAX_STEPS ||
        length != 3 + 3 * (usz)steps_value || learning_rate_value < 1 ||
        learning_rate_value > 1000000000 || epsilon_value < 1 || epsilon_value > 10000000) return -1;
    usz steps = (usz)steps_value;
    for (usz step = 0; step < steps; step++) {
        long id = input[3 + 3 * step];
        long parameter = input[4 + 3 * step];
        long gradient = input[5 + 3 * step];
        if (id < 0 || id >= (long)MAX_GROUPS || parameter < -1000000000000000L ||
            parameter > 1000000000000000L || gradient < -1000000000000L || gradient > 1000000000000L) return -1;
    }
    if (output == null || output_capacity < 8 * steps) return -2;

    double learning_rate = (double)learning_rate_value / INPUT_SCALE;
    double epsilon = (double)epsilon_value / INPUT_SCALE;
    double[MAX_GROUPS] accumulated = {0.0};
    for (usz step = 0; step < steps; step++) {
        usz id = (usz)input[3 + 3 * step];
        double parameter = (double)input[4 + 3 * step] / INPUT_SCALE;
        double gradient = (double)input[5 + 3 * step] / INPUT_SCALE;
        accumulated[id] += gradient * gradient;
        double updated = parameter - learning_rate / (adagrad_sqrt(accumulated[id]) + epsilon) * gradient;
        long encoded = (long)(updated * OUTPUT_SCALE);
        for (usz byte = 0; byte < 8; byte++) output[8 * step + byte] = (char)((encoded >> (byte * 8)) & 255);
    }
    return (long)steps;
}
