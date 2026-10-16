module horizontal_projectile_motion;

extern fn double sin(double value);

const double GRAVITY = 9.80665;
const long OUTPUT_BYTES = 24;

fn long round_cents(double value) {
    ulong bits = @bitcast(ulong, value);
    long exponent = ((bits >> 52) & 2047).long();
    if (exponent == 0) return 0;
    ulong mantissa = (1ul << 52) | (bits & 4503599627370495ul);
    ulong product = mantissa * 25ul;
    long right_shift = 1073 - exponent;
    if (right_shift >= 59) return 0;
    ulong rounded = product >> right_shift;
    ulong divisor = 1ul << right_shift;
    ulong remainder = product & (divisor - 1ul);
    ulong halfway = divisor >> 1;
    if (remainder > halfway || (remainder == halfway && (rounded & 1ul) != 0)) rounded += 1ul;
    if ((bits >> 63) != 0) return -rounded.long();
    return rounded.long();
}

fn void store_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

fn long horizontal_projectile_motion(long* values, usz length, char* output, usz output_capacity)
        @export("horizontal_projectile_motion") {
    if (values == null || length != 2) return -1;
    long velocity_milli = values[0], angle_millidegrees = values[1];
    if (velocity_milli < 0 || velocity_milli > 100000 ||
        angle_millidegrees < 1000 || angle_millidegrees > 90000) return -1;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;

    double velocity = (double)velocity_milli / 1000.0;
    double angle = (double)angle_millidegrees / 1000.0;
    double pi_over_180 = 3.14159265358979323846264338327950288 / 180.0;
    double distance_raw = velocity * velocity * sin((2.0 * angle) * pi_over_180) / GRAVITY;
    double angle_sine = sin(angle * pi_over_180);
    double height_raw = velocity * velocity * angle_sine * angle_sine / (2.0 * GRAVITY);
    double time_raw = (2.0 * velocity) * angle_sine / GRAVITY;
    store_f64_le(output, 0, (double)round_cents(distance_raw) / 100.0);
    store_f64_le(output, 8, (double)round_cents(height_raw) / 100.0);
    store_f64_le(output, 16, (double)round_cents(time_raw) / 100.0);
    return OUTPUT_BYTES;
}
