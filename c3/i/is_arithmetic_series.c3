module is_arithmetic_series;
const usz MAX_LENGTH = 64;
const long MAX_ABS_VALUE = 1000000L;
fn long is_arithmetic_series(long* values, usz length) @export("is_arithmetic_series") {
    if (values == null || length == 0 || length > MAX_LENGTH) return -1;
    for (usz i = 0; i < length; i++) { if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return -1; }
    if (length == 1) return 1;
    long difference = values[1] - values[0];
    for (usz i = 1; i + 1 < length; i++) { if (values[i + 1] - values[i] != difference) return 0; }
    return 1;
}
