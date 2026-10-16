module bezier_curve;

const long MAX_POINTS = 16;

fn double integer_power(double base, usz exponent) {
    double result = 1.0;
    for (usz i = 0; i < exponent; i++) { result *= base; }
    return result;
}

fn ulong choose(usz n, usz k_input) {
    usz k = k_input;
    if (k > n - k) k = n - k;
    ulong result = 1;
    for (usz i = 1; i <= k; i++) { result = result * (ulong)(n - k + i) / (ulong)i; }
    return result;
}

fn long round_scaled(double value) {
    double scaled = value * 1000000.0;
    return (long)(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits >> (8 * byte)); }
}

fn long bezier_curve(long* values, usz length, char* output, usz output_capacity)
        @export("bezier_curve") {
    if (values == null || length < 4 || length > 34) return -1;
    long point_count_value = values[0];
    long parameter_q = values[1];
    if (point_count_value < 1 || point_count_value > MAX_POINTS || parameter_q < 0 || parameter_q > 1000000) return -1;
    usz point_count = (usz)point_count_value;
    if (length != 2 + 2 * point_count) return -1;
    for (usz i = 2; i < length; i++) {
        if (values[i] < -1000000 || values[i] > 1000000) return -1;
    }
    if (output == null || output_capacity < 32) return -2;

    usz degree = point_count - 1;
    double t = (double)parameter_q / 1000000.0;
    double x = 0.0;
    double y = 0.0;
    double dx = 0.0;
    double dy = 0.0;
    for (usz i = 0; i < point_count; i++) {
        double weight = (double)choose(degree, i) * integer_power(1.0 - t, degree - i) * integer_power(t, i);
        x += weight * (double)values[2 + 2 * i];
        y += weight * (double)values[3 + 2 * i];
    }
    for (usz i = 0; i < degree; i++) {
        double weight = (double)degree * (double)choose(degree - 1, i) *
            integer_power(1.0 - t, degree - 1 - i) * integer_power(t, i);
        dx += weight * (double)(values[4 + 2 * i] - values[2 + 2 * i]);
        dy += weight * (double)(values[5 + 2 * i] - values[3 + 2 * i]);
    }
    write_i64_le(output, 0, round_scaled(x));
    write_i64_le(output, 8, round_scaled(y));
    write_i64_le(output, 16, round_scaled(dx));
    write_i64_le(output, 24, round_scaled(dy));
    return 32;
}
