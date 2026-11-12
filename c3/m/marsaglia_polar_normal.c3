module marsaglia_polar_normal;

extern fn double trunc(double value);
extern fn double sqrt(double value);
extern fn double log(double value);

const usz MAX_DRAWS = 128;
const usz MAX_ATTEMPTS = 64;
const double DRAW_SCALE = 2147483648.0;

fn bool is_bounded_integer(double value, double minimum, double maximum) {
    return value == value && trunc(value) == value && value >= minimum && value <= maximum;
}

fn long marsaglia_polar_normal(double* input, usz length, double* output, usz capacity)
    @export("marsaglia_polar_normal") {
    if (input == null || length < 4 || length > 2 + MAX_DRAWS) return -1;
    if (!is_bounded_integer(input[0], 2.0, (double)MAX_DRAWS) ||
        !is_bounded_integer(input[1], 1.0, (double)MAX_ATTEMPTS)) return -1;
    usz draw_count = (usz)input[0];
    usz attempt_cap = (usz)input[1];
    if ((draw_count & 1) != 0 || length != 2 + draw_count || draw_count < 2 * attempt_cap) return -1;
    for (usz index = 0; index < draw_count; index += 1)
        if (!is_bounded_integer(input[2 + index], 0.0, 4294967295.0)) return -1;

    double first = 0.0, second = 0.0;
    bool accepted = false;
    for (usz attempt = 0; attempt < attempt_cap; attempt += 1) {
        double u1 = input[2 + 2 * attempt] / DRAW_SCALE - 1.0;
        double u2 = input[3 + 2 * attempt] / DRAW_SCALE - 1.0;
        double radius_squared = u1 * u1 + u2 * u2;
        if (radius_squared <= 0.0 || radius_squared >= 1.0) continue;
        double scale = sqrt(-2.0 * log(radius_squared) / radius_squared);
        first = u1 * scale;
        second = u2 * scale;
        accepted = true;
        break;
    }
    if (!accepted) return -1;
    if (output == null || capacity < 2) return -2;
    output[0] = first;
    output[1] = second;
    return 2;
}
