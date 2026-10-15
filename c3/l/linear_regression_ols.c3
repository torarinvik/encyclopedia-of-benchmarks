module linear_regression_ols;

const usz MAX_OBSERVATIONS = 128;
const double INVALID_RESULT = -1.0e300;

fn double linear_regression_ols(long* values, usz length) @export("linear_regression_ols") {
    if (values == null || length < 5 || length > 1 + 2 * MAX_OBSERVATIONS || length % 2 == 0) return INVALID_RESULT;
    long count = values[0];
    if (count < 2 || count > 128 || length != 1 + 2 * (usz)count) return INVALID_RESULT;

    double sum_x = 0.0;
    double sum_y = 0.0;
    for (usz index = 0; index < (usz)count; index++) {
        long x = values[1 + 2 * index];
        long y = values[2 + 2 * index];
        if (x < -1000000 || x > 1000000 || y < -1000000 || y > 1000000) return INVALID_RESULT;
        sum_x += (double)x;
        sum_y += (double)y;
    }
    double mean_x = sum_x / (double)count;
    double mean_y = sum_y / (double)count;
    double covariance = 0.0;
    double variance_x = 0.0;
    double variance_y = 0.0;
    for (usz index = 0; index < (usz)count; index++) {
        double dx = (double)values[1 + 2 * index] - mean_x;
        double dy = (double)values[2 + 2 * index] - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x <= 1e-12 || variance_y <= 1e-12) return INVALID_RESULT;
    return covariance / variance_x;
}
