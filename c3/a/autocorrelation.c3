module autocorrelation;

const usz MAX_LENGTH = 64;
const double INVALID_RESULT = -1.0e300;

fn double autocorrelation(long* values, usz length) @export("autocorrelation") {
    if (values == null || length < 4 || length > MAX_LENGTH + 2) return INVALID_RESULT;
    long count_value = values[0];
    long lag_value = values[1];
    if (count_value < 2 || count_value > (long)MAX_LENGTH || length != (usz)count_value + 2 ||
        lag_value < 0 || lag_value >= count_value) return INVALID_RESULT;
    usz count = (usz)count_value;
    usz lag = (usz)lag_value;
    double sum = 0.0;
    for (usz index = 0; index < count; index++) {
        long value = values[index + 2];
        if (value < -1000 || value > 1000) return INVALID_RESULT;
        sum += (double)value;
    }
    double mean = sum / (double)count;
    double variance_sum = 0.0;
    for (usz index = 0; index < count; index++) {
        double difference = (double)values[index + 2] - mean;
        variance_sum += difference * difference;
    }
    if (variance_sum == 0.0) return INVALID_RESULT;
    double variance = variance_sum / (double)count;
    double covariance_sum = 0.0;
    for (usz index = lag; index < count; index++) {
        double current = (double)values[index + 2] - mean;
        double delayed = (double)values[index - lag + 2] - mean;
        covariance_sum += current * delayed;
    }
    double covariance = covariance_sum / (double)count;
    return covariance / variance;
}
