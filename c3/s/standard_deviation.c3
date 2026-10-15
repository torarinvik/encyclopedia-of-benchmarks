module standard_deviation;

extern fn double pow(double base, double exponent);
extern fn double sqrt(double value);
const usz MAX_LENGTH = 64;
const long MAX_ABS_VALUE = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double standard_deviation(long* values, usz length) @export("standard_deviation") {
    if (length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double sum = 0.0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += (double)value;
    }
    double average = sum / (double)length;
    double squared_deviations = 0.0;
    for (usz i = 0; i < length; i++) {
        double difference = (double)values[i] - average;
        squared_deviations += pow(difference, 2.0);
    }
    return sqrt(squared_deviations / (double)length);
}
