module variance;

const usz MAX_LENGTH = 64;
const long MAX_ABS_VALUE = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double variance(long* values, usz length) @export("variance") {
    if (values == null || length < 2 || length > MAX_LENGTH) return INVALID_RESULT;
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
        squared_deviations += difference * difference;
    }
    return squared_deviations / (double)(length - 1);
}
