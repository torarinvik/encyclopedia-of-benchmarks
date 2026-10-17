module single_point_crossover;

const usz MAX_PARENT_LENGTH = 31;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_PARENT_LENGTH;

fn bool finite_f64(double value) {
    return value == value && value - value == 0.0;
}

fn long single_point_crossover(double* input, usz input_length,
    double* output, usz output_capacity) @export("single_point_crossover") {
    if (input == null || input_length < 6 || input_length > MAX_INPUT_LENGTH) return -1;
    double n_value = input[0], cut_value = input[1];
    if (!finite_f64(n_value) || !finite_f64(cut_value)) return -1;
    if (n_value < 2.0 || n_value > 31.0 || n_value != (double)(long)n_value ||
        cut_value < 1.0 || cut_value > n_value - 1.0 || cut_value != (double)(long)cut_value) return -1;
    usz n = (usz)(long)n_value, cut = (usz)(long)cut_value;
    if (input_length != 2 + 2 * n) return -1;
    double first[31], second[31];
    for (usz index = 0; index < n; index++) {
        first[index] = input[2 + index];
        second[index] = input[2 + n + index];
        if (!finite_f64(first[index]) || !finite_f64(second[index])) return -1;
    }
    usz required = 2 * n;
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < n; index++) {
        if (index < cut) { output[index] = first[index]; output[n + index] = second[index]; }
        else { output[index] = second[index]; output[n + index] = first[index]; }
    }
    return (long)required;
}
