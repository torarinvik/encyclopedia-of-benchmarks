module mean_absolute_deviation;

extern fn double fabs(double value);
const usz MAX_LENGTH = 256;
const double INVALID_RESULT = -1.0e300;

fn double mean_absolute_deviation(long* values, usz length) @export("mean_absolute_deviation") {
    if (values == null || length < 2 || length > MAX_LENGTH + 1) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 1 || count_value > (long)MAX_LENGTH || length != (usz)count_value + 1) return INVALID_RESULT;
    usz count = (usz)count_value;
    double sum = 0.0;
    for (usz index = 0; index < count; index++) {
        long value = values[index + 1];
        if (value < -1000000 || value > 1000000) return INVALID_RESULT;
        sum += (double)value;
    }
    double mean = sum / (double)count;
    double absolute_sum = 0.0;
    for (usz index = 0; index < count; index++) {
        absolute_sum += fabs((double)values[index + 1] - mean);
    }
    return absolute_sum / (double)count;
}
