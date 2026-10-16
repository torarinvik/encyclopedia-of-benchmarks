module is_harmonic_series;

const usz MAX_VALUES = 32;
const double INVALID_RESULT = -1.0e300;

fn double is_harmonic_series(long* values, usz length) @export("is_harmonic_series") {
    if (values == null || length < 2 || length > MAX_VALUES + 1) return INVALID_RESULT;
    long count = values[0];
    if (count < 1 || count > (long)MAX_VALUES || length != (usz)count + 1) return INVALID_RESULT;

    double reciprocals[32];
    for (usz i = 0; i < (usz)count; i++) {
        double value = @bitcast(double, values[i + 1]);
        if (value == 0.0) return INVALID_RESULT;
        reciprocals[i] = 1.0 / value;
    }
    if (count == 1) return 1.0;
    double common_difference = reciprocals[1] - reciprocals[0];
    for (usz i = 2; i < (usz)count; i++)
        if (reciprocals[i] - reciprocals[i - 1] != common_difference) return 0.0;
    return 1.0;
}
