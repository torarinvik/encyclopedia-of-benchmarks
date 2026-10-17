module joint_probability_distribution;

const usz MAX_SUPPORT_LENGTH = 4;
const usz MAX_PARSEABLE_INPUT_LENGTH = 20;
const usz MAX_OUTPUT_ELEMENTS = 48;

fn bool parse_count(double raw, usz* count) {
    if (raw != raw || raw < 1.0 || raw > 4.0) return false;
    long parsed = (long)raw;
    if ((double)parsed != raw) return false;
    *count = (usz)parsed;
    return true;
}

fn bool parse_support(double raw, long* support) {
    if (raw != raw || raw < -1000.0 || raw > 1000.0) return false;
    long parsed = (long)raw;
    if ((double)parsed != raw) return false;
    *support = parsed;
    return true;
}

fn bool valid_probability(double value) {
    return value == value && value >= -1000000.0 && value <= 1000000.0;
}

fn long joint_probability_distribution(double* input, usz input_length,
        double* output, usz output_capacity) @export("joint_probability_distribution") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    usz x_count, y_count;
    if (!parse_count(input[0], &x_count) || !parse_count(input[1], &y_count)) return -1;
    if (input_length != 2 + 2 * x_count + 2 * y_count) return -1;

    usz x_start = 2;
    usz y_start = x_start + x_count;
    usz x_probability_start = y_start + y_count;
    usz y_probability_start = x_probability_start + x_count;
    long[4] x_values, y_values;
    double[4] x_probabilities, y_probabilities;

    for (usz index = 0; index < x_count; index++) {
        if (!parse_support(input[x_start + index], &x_values[index]) ||
            !valid_probability(input[x_probability_start + index])) return -1;
        x_probabilities[index] = input[x_probability_start + index];
        for (usz previous = 0; previous < index; previous++)
            if (x_values[previous] == x_values[index]) return -1;
    }
    for (usz index = 0; index < y_count; index++) {
        if (!parse_support(input[y_start + index], &y_values[index]) ||
            !valid_probability(input[y_probability_start + index])) return -1;
        y_probabilities[index] = input[y_probability_start + index];
        for (usz previous = 0; previous < index; previous++)
            if (y_values[previous] == y_values[index]) return -1;
    }

    usz required = 3 * x_count * y_count;
    if (required > MAX_OUTPUT_ELEMENTS) return -1;
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    for (usz x_index = 0; x_index < x_count; x_index++) {
        for (usz y_index = 0; y_index < y_count; y_index++) {
            output[position++] = (double)x_values[x_index];
            output[position++] = (double)y_values[y_index];
            output[position++] = x_probabilities[x_index] * y_probabilities[y_index];
        }
    }
    return (long)required;
}
