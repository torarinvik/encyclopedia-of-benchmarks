module rmsprop;

extern fn double pow(double base, double exponent);
extern fn double sqrt(double value);

const double MAX_FINITE = 1.7976931348623157e308;
const usz MAX_PARSEABLE_INPUT_LENGTH = 102;
const usz MAX_VECTOR_LENGTH = 32;

fn bool finite_value(double value) {
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE;
}

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn double rounded_subtract(double left, double right) @noinline {
    return left - right;
}

fn double rounded_divide(double left, double right) @noinline {
    return left / right;
}

fn long rmsprop(double* input, usz input_length, double* output, usz output_capacity)
    @export("rmsprop")
{
    if (input == null || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (usz i = 0; i < input_length; i++) {
        if (!finite_value(input[i])) return -1;
    }

    double count_value = input[0];
    double state_mode_value = input[1];
    if (count_value < 0.0 || count_value > (double)MAX_VECTOR_LENGTH) return -1;
    long count_long = (long)count_value;
    if (count_value != (double)count_long) return -1;
    if (state_mode_value != 0.0 && state_mode_value != 1.0) return -1;
    bool state_mode = state_mode_value == 1.0;
    usz count = (usz)count_long;

    usz expected_length = 5 + 2 * count + (state_mode ? count : 0);
    if (input_length != expected_length) return -1;

    double learning_rate = input[2];
    double rho = input[3];
    double epsilon = input[4];
    if (learning_rate < 1e-6 || learning_rate > 1.0 ||
        rho < 0.0 || rho > 0.99 || epsilon < 1e-8 || epsilon > 1.0) return -1;

    usz gradients_start = 5 + count;
    usz moving_average_start = 5 + 2 * count;
    double[MAX_VECTOR_LENGTH] moving_average;
    double[MAX_VECTOR_LENGTH] updated_params;
    double[MAX_VECTOR_LENGTH] updated_average;
    for (usz i = 0; i < count; i++) {
        double parameter = input[5 + i];
        double gradient = input[gradients_start + i];
        if (parameter < -100.0 || parameter > 100.0 ||
            gradient < -100.0 || gradient > 100.0) return -1;
        moving_average[i] = state_mode ? input[moving_average_start + i] : 0.0;
        if (moving_average[i] < 0.0 || moving_average[i] > 10000.0) return -1;
    }

    if (output == null || output_capacity < 2 * count) return -2;

    for (usz i = 0; i < count; i++) {
        double parameter = input[5 + i];
        double gradient = input[gradients_start + i];
        double weighted_previous = rounded_multiply(rho, moving_average[i]);
        double one_minus_rho = rounded_subtract(1.0, rho);
        double squared_gradient = pow(gradient, 2.0);
        double weighted_gradient = rounded_multiply(one_minus_rho, squared_gradient);
        double new_average = rounded_add(weighted_previous, weighted_gradient);
        double sqrt_argument = rounded_add(new_average, epsilon);
        double denominator = sqrt(sqrt_argument);
        double scale = rounded_divide(learning_rate, denominator);
        double step = rounded_multiply(scale, gradient);
        updated_params[i] = rounded_subtract(parameter, step);
        updated_average[i] = new_average;
    }

    for (usz i = 0; i < count; i++) {
        output[i] = updated_params[i];
        output[count + i] = updated_average[i];
    }
    return (long)(2 * count);
}
