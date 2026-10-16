module spearman_avg_rank;

extern fn double sqrt(double value);
const double INVALID_RESULT = -1.0e300;

fn double average_rank(long* samples, usz count, usz index) {
    long less = 0;
    long equal = 0;
    for (usz j = 0; j < count; j++) {
        if (samples[j] < samples[index]) less++;
        if (samples[j] == samples[index]) equal++;
    }
    return (double)less + ((double)equal + 1.0) / 2.0;
}

fn double spearman_average_rank_correlation(long* values, usz length) @export("spearman_average_rank_correlation") {
    if (values == null || length < 5 || length > 257) return INVALID_RESULT;
    long count = values[0];
    if (count < 2 || count > 128 || length != 1 + 2 * (usz)count) return INVALID_RESULT;
    usz n = (usz)count;
    for (usz i = 0; i < 2 * n; i++) {
        if (values[1 + i] < -1000000 || values[1 + i] > 1000000) return INVALID_RESULT;
    }
    double mean_rank = ((double)n + 1.0) / 2.0;
    double covariance = 0.0;
    double variance_x = 0.0;
    double variance_y = 0.0;
    for (usz i = 0; i < n; i++) {
        double dx = average_rank(values + 1, n, i) - mean_rank;
        double dy = average_rank(values + 1 + n, n, i) - mean_rank;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x == 0.0 || variance_y == 0.0) return INVALID_RESULT;
    return covariance / sqrt(variance_x * variance_y);
}
