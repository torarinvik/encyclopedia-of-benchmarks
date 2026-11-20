module circular_mean_direction;

extern fn double sin(double value);
extern fn double cos(double value);
extern fn double atan2(double y, double x);
extern fn double floor(double value);
extern fn double sqrt(double value);
extern fn double fabs(double value);
extern fn double trunc(double value);

const double PI_VALUE = 3.14159265358979323846264338327950288;
const double TAU_VALUE = 6.28318530717958647692528676655900576;

fn double wrap_angle(double angle) {
    double value = angle - floor((angle + PI_VALUE) / TAU_VALUE) * TAU_VALUE;
    if (value >= PI_VALUE) value -= TAU_VALUE;
    if (value < -PI_VALUE) value += TAU_VALUE;
    return value;
}

fn long circular_mean_direction(double* input, usz length, double* output, usz capacity)
    @export("circular_mean_direction") {
    if (input == null || length < 2 || length > 66) return -1;
    double count_value = input[0];
    if (count_value != count_value || trunc(count_value) != count_value ||
        count_value < 1.0 || count_value > 64.0) return -1;
    usz count = (usz)count_value;
    if (length != count + 1) return -1;

    double sum_cos = 0.0, sum_sin = 0.0;
    double correction_cos = 0.0, correction_sin = 0.0;
    for (usz index = 0; index < count; index += 1) {
        double raw = input[index + 1];
        if (raw != raw || fabs(raw) > 8.0 * PI_VALUE) return -1;
        double angle = wrap_angle(raw);
        double adjusted_cos = cos(angle) - correction_cos;
        double next_cos = sum_cos + adjusted_cos;
        correction_cos = (next_cos - sum_cos) - adjusted_cos;
        sum_cos = next_cos;
        double adjusted_sin = sin(angle) - correction_sin;
        double next_sin = sum_sin + adjusted_sin;
        correction_sin = (next_sin - sum_sin) - adjusted_sin;
        sum_sin = next_sin;
    }
    double resultant = sqrt(sum_cos * sum_cos + sum_sin * sum_sin);
    if (resultant != resultant || resultant <= (double)count * 0.0000000037252902984619140625) return -1;
    if (output == null || capacity < 1) return -2;
    output[0] = wrap_angle(atan2(sum_sin, sum_cos));
    return 1;
}
