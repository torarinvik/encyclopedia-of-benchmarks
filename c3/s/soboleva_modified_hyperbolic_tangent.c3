module soboleva_modified_hyperbolic_tangent;

extern fn double exp(double value);

const double MAX_FINITE = 1.7976931348623157e308;
const usz MAX_PARSEABLE_INPUT_LENGTH = 38;

fn bool finite_value(double value) {
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE;
}

fn long soboleva_modified_hyperbolic_tangent(double* input, usz input_length,
                                             double* output, usz output_capacity)
    @export("soboleva_modified_hyperbolic_tangent")
{
    if (input == null || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (usz i = 0; i < input_length; i++) {
        if (!finite_value(input[i])) return -1;
    }

    double count_value = input[0];
    if (count_value < 1.0 || count_value > 32.0) return -1;
    long count_long = (long)count_value;
    if (count_value != (double)count_long) return -1;
    usz count = (usz)count_long;
    if (input_length != 5 + count) return -1;

    double a = input[1], b = input[2], c = input[3], d = input[4];
    if (a < -2.0 || a > 2.0 || b < -2.0 || b > 2.0 ||
        c < -2.0 || c > 2.0 || d < -2.0 || d > 2.0) return -1;
    for (usz i = 0; i < count; i++) {
        if (input[5 + i] < -20.0 || input[5 + i] > 20.0) return -1;
    }

    if (output == null || output_capacity < count) return -2;
    for (usz i = 0; i < count; i++) {
        double x = input[5 + i];
        double ax = a * x;
        double neg_b_x = (-b) * x;
        double cx = c * x;
        double neg_d_x = (-d) * x;
        double numerator = exp(ax) - exp(neg_b_x);
        double denominator = exp(cx) + exp(neg_d_x);
        output[i] = numerator / denominator;
    }
    return (long)count;
}
