module spirograph;

extern fn double cos(double value);
extern fn double sin(double value);

const usz MAX_POINTS = 32;
const usz MAX_PARSEABLE_INPUT_LENGTH = 5;
const usz MAX_OUTPUT_ELEMENTS = 64;

fn bool finite_value(double value) {
    return value == value && value >= -1e308 && value <= 1e308;
}

fn bool exact_point_count(double value, usz* point_count) {
    if (!finite_value(value) || value < 1.0 || value > (double)MAX_POINTS) return false;
    long converted = (long)value;
    if ((double)converted != value) return false;
    *point_count = (usz)converted;
    return true;
}

fn long spirograph(double* input, usz input_length, double* output, usz output_capacity)
    @export("spirograph") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH ||
        input_length != 4) return -1L;

    usz point_count;
    if (!exact_point_count(input[0], &point_count)) return -1L;
    double marker_ratio = input[1];
    double inner_ratio = input[2];
    double rotations = input[3];
    if (!finite_value(marker_ratio) || marker_ratio < 0.0 || marker_ratio > 1.0 ||
        !finite_value(inner_ratio) || inner_ratio < 0.25 || inner_ratio > 0.75 ||
        !finite_value(rotations) || rotations < 0.0 || rotations > 10.0) return -1L;

    double pi = 3.141592653589793238462643383279502884;
    double delta = rotations * 2.0 * pi / (double)point_count;
    double outer_ratio = 1.0 - inner_ratio;
    double marker_radius = marker_ratio * inner_ratio;
    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    for (usz index = 0; index < point_count; index++) {
        double t = delta * (double)index;
        double inner_angle = outer_ratio * t / inner_ratio;
        double x = outer_ratio * cos(t) + marker_radius * cos(inner_angle);
        double y = outer_ratio * sin(t) - marker_radius * sin(inner_angle);
        if (!finite_value(x) || !finite_value(y)) return -1L;
        staged[2 * index] = x;
        staged[2 * index + 1] = y;
    }

    usz output_length = 2 * point_count;
    if (output == null || output_capacity < output_length) return -2L;
    for (usz index = 0; index < output_length; index++) output[index] = staged[index];
    return (long)output_length;
}
