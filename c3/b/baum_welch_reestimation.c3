module baum_welch_reestimation;

const usz BW_MAX_INPUT = 48;
const usz BW_MAX_OUTPUT = 36;
const double BW_MIN_PROBABILITY = 0.001;
const double BW_ROW_TOLERANCE = 1e-9;

fn bool bw_exact_integer(double value, long low, long high, long* decoded) {
    if (value != value || value < (double)low || value > (double)high || (double)(long)value != value) return false;
    *decoded = (long)value;
    return true;
}

fn bool bw_valid_row(double* row, usz count) {
    double total = 0.0;
    for (usz i = 0; i < count; i++) {
        if (row[i] != row[i] || row[i] < BW_MIN_PROBABILITY || row[i] > 1.0) return false;
        total += row[i];
    }
    double difference = total - 1.0;
    if (difference < 0.0) difference = -difference;
    return difference <= BW_ROW_TOLERANCE;
}

fn long baum_welch_reestimation(double* input, usz input_length, double* output, usz output_capacity)
        @export("baum_welch_reestimation") {
    if (input == null || input_length < 3 || input_length > BW_MAX_INPUT) return -1;
    long states_value; long symbols_value; long time_value;
    if (!bw_exact_integer(input[0], 2, 4, &states_value) || !bw_exact_integer(input[1], 2, 4, &symbols_value) ||
        !bw_exact_integer(input[2], 1, 8, &time_value)) return -1;
    usz states = (usz)states_value; usz symbols = (usz)symbols_value; usz time_count = (usz)time_value;
    usz required = 3 + states + states * states + states * symbols + time_count;
    if (input_length != required) return -1;

    double[4] initial = zeroed;
    double[16] transition = zeroed;
    double[16] emission = zeroed;
    long[8] observations = zeroed;
    usz cursor = 3;
    for (usz i = 0; i < states; i++) initial[i] = input[cursor++];
    for (usz i = 0; i < states * states; i++) transition[i] = input[cursor++];
    for (usz i = 0; i < states * symbols; i++) emission[i] = input[cursor++];
    if (!bw_valid_row(&initial[0], states)) return -1;
    for (usz state = 0; state < states; state++) {
        if (!bw_valid_row(&transition[state * states], states) || !bw_valid_row(&emission[state * symbols], symbols)) return -1;
    }
    for (usz time = 0; time < time_count; time++)
        if (!bw_exact_integer(input[cursor + time], 0, (long)symbols - 1, &observations[time])) return -1;

    double[32] alpha = zeroed;
    double[32] beta = zeroed;
    double[32] gamma = zeroed;
    double[36] staged = zeroed;
    for (usz state = 0; state < states; state++) alpha[state] = initial[state] * emission[state * symbols + (usz)observations[0]];
    for (usz time = 1; time < time_count; time++) {
        for (usz destination = 0; destination < states; destination++) {
            double incoming = 0.0;
            for (usz source = 0; source < states; source++) incoming += alpha[(time - 1) * states + source] * transition[source * states + destination];
            alpha[time * states + destination] = incoming * emission[destination * symbols + (usz)observations[time]];
        }
    }
    double likelihood = 0.0;
    for (usz state = 0; state < states; state++) likelihood += alpha[(time_count - 1) * states + state];
    for (usz state = 0; state < states; state++) beta[(time_count - 1) * states + state] = 1.0;
    usz time = time_count - 1;
    while (time > 0) {
        time -= 1;
        for (usz source = 0; source < states; source++) {
            double sum = 0.0;
            for (usz destination = 0; destination < states; destination++) sum += transition[source * states + destination] * emission[destination * symbols + (usz)observations[time + 1]] * beta[(time + 1) * states + destination];
            beta[time * states + source] = sum;
        }
    }
    for (usz t = 0; t < time_count; t++)
        for (usz state = 0; state < states; state++) gamma[t * states + state] = alpha[t * states + state] * beta[t * states + state] / likelihood;

    usz output_count = states + states * states + states * symbols;
    usz out = 0;
    for (usz state = 0; state < states; state++) staged[out++] = gamma[state];
    if (time_count == 1) {
        for (usz i = 0; i < states * states; i++) staged[out++] = transition[i];
    } else {
        for (usz source = 0; source < states; source++) {
            double denominator = 0.0;
            for (usz t = 0; t + 1 < time_count; t++) denominator += gamma[t * states + source];
            for (usz destination = 0; destination < states; destination++) {
                double count = 0.0;
                for (usz t = 0; t + 1 < time_count; t++) count += alpha[t * states + source] * transition[source * states + destination] * emission[destination * symbols + (usz)observations[t + 1]] * beta[(t + 1) * states + destination] / likelihood;
                staged[out++] = count / denominator;
            }
        }
    }
    for (usz state = 0; state < states; state++) {
        double denominator = 0.0;
        for (usz t = 0; t < time_count; t++) denominator += gamma[t * states + state];
        for (usz symbol = 0; symbol < symbols; symbol++) {
            double count = 0.0;
            for (usz t = 0; t < time_count; t++) if ((usz)observations[t] == symbol) count += gamma[t * states + state];
            staged[out++] = count / denominator;
        }
    }
    if (out != output_count) return -1;
    if (output == null || output_capacity < output_count) return -2;
    for (usz i = 0; i < output_count; i++) output[i] = staged[i];
    return (long)output_count;
}
