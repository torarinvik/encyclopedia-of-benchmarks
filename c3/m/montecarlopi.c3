module montecarlopi;

const usz MIN_RANDOM_POINTS = 1;
const usz MAX_RANDOM_POINTS = 64;
const usz MAX_INPUT_LENGTH = 130;

fn bool finite_value(double value) {
    return value == value && value >= -1.7976931348623157e308 &&
           value <= 1.7976931348623157e308;
}

fn bool exact_sample_count(double value, usz* count) {
    if (!finite_value(value) || value < (double)MIN_RANDOM_POINTS ||
        value > (double)MAX_RANDOM_POINTS) return false;
    long converted = (long)value;
    if ((double)converted != value) return false;
    *count = (usz)converted;
    return true;
}

fn double rounded_divide(double numerator, double denominator) @noinline {
    return numerator / denominator;
}

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn bool allowed_coordinate(double value) {
    return value == 0.0 || value == 0.25 || value == 0.5 || value == 0.75;
}

fn long montecarlopi(double* values, usz length, double* output, usz output_capacity)
    @export("montecarlopi") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < length; index++)
        if (!finite_value(values[index])) return -1L;

    usz random_points;
    if (!exact_sample_count(values[0], &random_points) ||
        length != 1 + 2 * random_points) return -1L;

    usz inside = 0;
    for (usz index = 0; index < random_points; index++) {
        double x = values[1 + 2 * index];
        double y = values[2 + 2 * index];
        if (!allowed_coordinate(x) || !allowed_coordinate(y)) return -1L;
        double x_squared = rounded_multiply(x, x);
        double y_squared = rounded_multiply(y, y);
        double squared_radius = x_squared + y_squared;
        if (squared_radius <= 1.0) inside++;
    }

    double fraction = rounded_divide((double)inside, (double)random_points);
    double estimate = rounded_multiply(fraction, 4.0);
    if (!finite_value(estimate)) return -1L;

    if (output == null || output_capacity < 1) return -2L;
    output[0] = estimate;
    return 1L;
}
