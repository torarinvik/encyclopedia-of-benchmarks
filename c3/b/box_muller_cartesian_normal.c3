module box_muller_cartesian_normal;

extern fn double trunc(double value);
extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double cos(double value);
extern fn double sin(double value);

const usz MAX_PAIRS = 64;
const double DRAW_SCALE = 4294967296.0;
const double TAU = 6.283185307179586476925286766559;

fn bool is_bounded_integer(double value, double minimum, double maximum) {
    return value == value && trunc(value) == value && value >= minimum && value <= maximum;
}

fn long box_muller_cartesian_normal(double* input, usz length, double* output, usz capacity)
    @export("box_muller_cartesian_normal") {
    if (input == null || length < 2 || length > 1 + 2 * MAX_PAIRS) return -1;
    if (!is_bounded_integer(input[0], 1.0, (double)MAX_PAIRS)) return -1;
    usz pair_count = (usz)input[0];
    if (length != 1 + 2 * pair_count) return -1;
    for (usz index = 0; index < 2 * pair_count; index += 1)
        if (!is_bounded_integer(input[1 + index], 0.0, 4294967295.0)) return -1;

    usz result_count = 2 * pair_count;
    if (output == null || capacity < result_count) return -2;
    for (usz pair = 0; pair < pair_count; pair += 1) {
        double radial = (input[1 + 2 * pair] + 1.0) / DRAW_SCALE;
        double angular = input[2 + 2 * pair] / DRAW_SCALE;
        double radius = sqrt(-2.0 * log(radial));
        double angle = TAU * angular;
        output[2 * pair] = radius * cos(angle);
        output[2 * pair + 1] = radius * sin(angle);
    }
    return (long)result_count;
}
