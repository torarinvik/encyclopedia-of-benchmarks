module wynn_epsilon_sequence_algorithm;

const usz MAX_N = 10;
const usz MAX_INPUT_LENGTH = 13;
const usz MAX_ORDER = 6;

fn bool wynn_finite(double value) {
    return value == value && value <= 1.7976931348623157e308
        && value >= -1.7976931348623157e308;
}

fn long wynn_epsilon_sequence_algorithm(double* input, usz input_length,
                                        double* output, usz output_capacity)
        @export("wynn_epsilon_sequence_algorithm") {
    if (input == null || input_length < 3 || input_length > MAX_INPUT_LENGTH) return -1;
    for (usz i = 0; i < input_length; i++) if (!wynn_finite(input[i])) return -1;
    double n_value = input[0], k_value = input[1];
    if (n_value < 5.0 || n_value > (double)MAX_N || k_value < 2.0 || k_value > 3.0) return -1;
    long n0 = (long)n_value, k0 = (long)k_value;
    if ((double)n0 != n_value || (double)k0 != k_value) return -1;
    usz n = (usz)n0, k = (usz)k0;
    if (n < 2 * k + 1 || input_length != n + 2) return -1;
    for (usz i = 0; i < n; i++) {
        double sample = input[i + 2], scaled = sample * 256.0;
        if (sample < -2.0 || sample > 2.0 || (double)(long)scaled != scaled) return -1;
    }

    double[MAX_ORDER + 1][MAX_N] rows = zeroed;
    bool[MAX_ORDER + 1][MAX_N] valid = zeroed;
    for (usz i = 0; i < n; i++) { rows[0][i] = input[i + 2]; valid[0][i] = true; }
    for (usz order = 0; order < 2 * k; order++) {
        usz width = n - order - 1;
        for (usz i = 0; i < width; i++) {
            bool auxiliary_valid = true;
            if (order != 0) auxiliary_valid = valid[order - 1][i + 1];
            if (!valid[order][i] || !valid[order][i + 1] || !auxiliary_valid) continue;
            double denominator = rows[order][i + 1] - rows[order][i];
            if (denominator == 0.0 || !wynn_finite(denominator)) continue;
            double reciprocal = 1.0 / denominator;
            double auxiliary = 0.0;
            if (order != 0) auxiliary = rows[order - 1][i + 1];
            double value = auxiliary + reciprocal;
            if (!wynn_finite(reciprocal) || !wynn_finite(value)) continue;
            rows[order + 1][i] = value;
            valid[order + 1][i] = true;
        }
    }

    usz needed = 0;
    for (usz order = 2; order <= 2 * k; order += 2) needed += 2 * (n - order);
    if (output == null || output_capacity < needed) return -2;
    usz cursor = 0;
    for (usz order = 2; order <= 2 * k; order += 2) {
        for (usz i = 0; i < n - order; i++) {
            output[cursor++] = valid[order][i] ? 0.0 : 1.0;
            output[cursor++] = valid[order][i] ? rows[order][i] : 0.0;
        }
    }
    return (long)needed;
}
