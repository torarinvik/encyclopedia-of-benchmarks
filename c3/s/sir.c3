module sir;

const long INVALID_RESULT = -1L;
const long OUTPUT_ERROR = -2L;
const usz INPUT_LENGTH = 6;
const usz MAX_PARSEABLE_INPUT_LENGTH = 7;

fn bool in_range(double value, double minimum, double maximum) {
    return value >= minimum && value <= maximum;
}

fn long sir(double* input, usz input_length, double* output, usz output_capacity)
    @export("sir") {
    if (input == null || input_length < INPUT_LENGTH || input_length > MAX_PARSEABLE_INPUT_LENGTH)
        return INVALID_RESULT;
    if (input_length != INPUT_LENGTH) return INVALID_RESULT;

    double s = input[0];
    double i = input[1];
    double r = input[2];
    double beta = input[3];
    double k = input[4];
    double time = input[5];
    if (!in_range(s, 0.0, 1000000.0) || !in_range(i, 0.0, 1000000.0) ||
        !in_range(r, 0.0, 1000000.0) || !in_range(beta, 0.0, 0.001) ||
        !in_range(k, 0.0, 1.0) || !in_range(time, 0.0, 140.0))
        return INVALID_RESULT;

    double d_s = ((-beta) * s) * i;
    double d_i_infection = (beta * s) * i;
    double d_i_recovery = k * i;
    double d_i = d_i_infection - d_i_recovery;
    double d_r = k * i;

    if (output == null || output_capacity < 3) return OUTPUT_ERROR;
    output[0] = d_s;
    output[1] = d_i;
    output[2] = d_r;
    return 3L;
}
