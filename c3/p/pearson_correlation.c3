module pearson_correlation;

extern fn double sqrt(double value);
const usz MAX_OBSERVATIONS = 128;
const long MAX_ABS_VALUE = 1000000L;
const double INVALID_RESULT = -1.0e300;

fn double pearson_correlation(long* values, usz length) @export("pearson_correlation") {
    if (values == null || length < 5 || length > 257) return INVALID_RESULT;
    long count = values[0];
    if (count < 2 || count > (long)MAX_OBSERVATIONS || length != 1 + 2 * (usz)count) return INVALID_RESULT;

    double sum_x = 0.0;
    double sum_y = 0.0;
    for (usz i = 0; i < (usz)count; i++) {
        long x = values[1 + i];
        long y = values[1 + (usz)count + i];
        if (x < -MAX_ABS_VALUE || x > MAX_ABS_VALUE || y < -MAX_ABS_VALUE || y > MAX_ABS_VALUE) return INVALID_RESULT;
        sum_x += (double)x;
        sum_y += (double)y;
    }
    double mean_x = sum_x / (double)count;
    double mean_y = sum_y / (double)count;
    double covariance = 0.0;
    double variance_x = 0.0;
    double variance_y = 0.0;
    for (usz i = 0; i < (usz)count; i++) {
        double dx = (double)values[1 + i] - mean_x;
        double dy = (double)values[1 + (usz)count + i] - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x == 0.0 || variance_y == 0.0) return INVALID_RESULT;
    return covariance / sqrt(variance_x * variance_y);
}
