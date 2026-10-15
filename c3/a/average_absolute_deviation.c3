module average_absolute_deviation;
const usz MAX_LENGTH = 256;
const long MIN_VALUE = -2147483648;
const long MAX_VALUE = 2147483647;
const double INVALID_RESULT = -1.0e300;
fn double average_absolute_deviation(long* values, usz length) @export("average_absolute_deviation") {
    if (length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double sum = 0.0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < MIN_VALUE || value > MAX_VALUE) return INVALID_RESULT;
        sum += (double)value;
    }
    double average = sum / (double)length;
    double deviations = 0.0;
    for (usz i = 0; i < length; i++) {
        double value = (double)values[i];
        deviations += value >= average ? value - average : average - value;
    }
    return deviations / (double)length;
}
