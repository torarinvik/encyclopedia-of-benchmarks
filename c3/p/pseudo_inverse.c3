module pseudo_inverse;

const usz MAX_ROWS = 4;
const usz MAX_INPUT_LENGTH = 7;
const double SINGULAR_VALUE_CUTOFF = 1e-4;

extern fn double sqrt(double value);
extern fn double fabs(double value);
extern fn double trunc(double value);

bool finite_value(double value) {
    return value == value && value - value == 0.0;
}

bool integer_in_range(double value, int minimum, int maximum) {
    return finite_value(value) && value >= (double)minimum && value <= (double)maximum && value == trunc(value);
}

fn long pseudo_inverse(double* input, usz input_length, double* output, usz output_capacity)
    @export("pseudo_inverse") {
    if (input == null || input_length < 3 || input_length > MAX_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < input_length; index++) {
        if (!finite_value(input[index])) return -1L;
    }
    if (!integer_in_range(input[0], 1, (int)MAX_ROWS) || !integer_in_range(input[1], 1, 1)) return -1L;
    usz row_count = (usz)(long)input[0];
    usz column_count = (usz)(long)input[1];
    if (input_length != 2 + row_count * column_count || input_length > 2 + MAX_ROWS) return -1L;

    double[MAX_ROWS] column = zeroed;
    double squared_norm = 0.0;
    for (usz row = 0; row < row_count; row++) {
        double value = input[2 + row];
        if (value < -4.0 || value > 4.0 || value != trunc(value)) return -1L;
        column[row] = value;
        squared_norm += value * value;
    }
    double singular_value = sqrt(squared_norm);
    double[MAX_ROWS + 2] staged = zeroed;
    staged[0] = 1.0;
    staged[1] = (double)row_count;
    for (usz row = 0; row < row_count; row++) {
        staged[2 + row] = fabs(singular_value) < SINGULAR_VALUE_CUTOFF
            ? 0.0 : column[row] / squared_norm;
    }

    usz result_length = 2 + row_count;
    if (output == null || output_capacity < result_length) return -2L;
    for (usz index = 0; index < result_length; index++) output[index] = staged[index];
    return (long)result_length;
}
