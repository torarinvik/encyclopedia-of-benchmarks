module arithmetic_mean;
const usz MAX_LENGTH = 64;
const long MAX_ABS_VALUE = 1000000L;
fn bool valid_values(long* values, usz length) {
    if (values == null || length == 0 || length > MAX_LENGTH) return false;
    for (usz i = 0; i < length; i++) { if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return false; }
    return true;
}
fn double arithmetic_mean(long* values, usz length) @export("arithmetic_mean") {
    if (!valid_values(values, length)) return -1.0e300;
    long total = 0;
    for (usz i = 0; i < length; i++) total += values[i];
    return (double)total / (double)length;
}
