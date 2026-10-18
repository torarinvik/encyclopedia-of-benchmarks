module kalman_filter_r_two_state_simulation;

const usz MAX_OBSERVATIONS = 12;
const usz MAX_PARSEABLE_LENGTH = 64;
const usz MAX_OUTPUT_ELEMENTS = 30;

fn bool finite_value(double value) {
    return value == value && value < 1e300 && value > -1e300;
}

fn void multiply_2x2(double* left, double* right, double* result) {
    for (usz row = 0; row < 2; row++) {
        for (usz column = 0; column < 2; column++) {
            double sum = 0.0;
            for (usz inner = 0; inner < 2; inner++)
                sum += left[row * 2 + inner] * right[inner * 2 + column];
            result[row * 2 + column] = sum;
        }
    }
}

fn long kalman_filter_r_two_state_simulation(double* input, usz input_length,
                                             double* output, usz output_capacity)
    @export("kalman_filter_r_two_state_simulation") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_LENGTH ||
        input_length > MAX_OBSERVATIONS) return -1L;
    for (usz i = 0; i < input_length; i++) {
        if (!finite_value(input[i]) || input[i] < -1000.0 || input[i] > 1000.0) return -1L;
    }

    double[4] transition = {1.0, 0.0, 1.0, 1.0};
    double[4] transition_t = {1.0, 1.0, 0.0, 1.0};
    double[2] state = {input[0], 0.0};
    double[4] covariance = {1.0, 0.0, 0.0, 1.0};
    double[2 * MAX_OBSERVATIONS] trace = zeroed;
    double[2] final_state_pred = zeroed;
    double[4] final_covariance_pred = zeroed;

    for (usz step = 0; step < input_length; step++) {
        for (usz i = 0; i < 2; i++) {
            double sum = 0.0;
            for (usz j = 0; j < 2; j++) sum += transition[i * 2 + j] * state[j];
            final_state_pred[i] = sum;
        }

        double[4] temp = zeroed;
        multiply_2x2(&transition[0], &covariance[0], &temp[0]);
        multiply_2x2(&temp[0], &transition_t[0], &final_covariance_pred[0]);
        final_covariance_pred[0] += 0.0001;
        final_covariance_pred[3] += 0.0001;

        double[2] h_pred = zeroed;
        for (usz column = 0; column < 2; column++) {
            double sum = 0.0;
            sum += 1.0 * final_covariance_pred[column];
            sum += 0.0 * final_covariance_pred[2 + column];
            h_pred[column] = sum;
        }
        double innovation = 0.0;
        innovation += h_pred[0] * 1.0;
        innovation += h_pred[1] * 0.0;
        innovation += 0.1;

        double[2] gain = zeroed;
        double inverse_innovation = 1.0 / innovation;
        for (usz row = 0; row < 2; row++) {
            double projected = 0.0;
            projected += final_covariance_pred[row * 2] * 1.0;
            projected += final_covariance_pred[row * 2 + 1] * 0.0;
            gain[row] = projected * inverse_innovation;
        }
        double h_state_pred = 0.0;
        h_state_pred += 1.0 * final_state_pred[0];
        h_state_pred += 0.0 * final_state_pred[1];
        double residual = input[step] - h_state_pred;
        for (usz row = 0; row < 2; row++) state[row] = final_state_pred[row] + gain[row] * residual;
        trace[2 * step] = state[0];
        trace[2 * step + 1] = state[1];

        double[4] gain_observation = {gain[0] * 1.0, gain[0] * 0.0,
                                      gain[1] * 1.0, gain[1] * 0.0};
        double[4] update = zeroed;
        for (usz i = 0; i < 4; i++) update[i] = 1.0 - gain_observation[i];
        multiply_2x2(&update[0], &final_covariance_pred[0], &covariance[0]);
    }

    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    usz out = 0;
    for (usz i = 0; i < 2 * input_length; i++) staged[out++] = trace[i];
    staged[out++] = final_state_pred[0];
    staged[out++] = final_state_pred[1];
    staged[out++] = final_covariance_pred[0];
    staged[out++] = final_covariance_pred[2];
    staged[out++] = final_covariance_pred[1];
    staged[out++] = final_covariance_pred[3];
    usz result_length = out;
    if (output == null || output_capacity < result_length) return -2L;
    for (usz i = 0; i < result_length; i++) output[i] = staged[i];
    return (long)result_length;
}
