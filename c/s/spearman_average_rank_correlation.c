#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double average_rank(const int64_t *samples, size_t count, size_t index) {
    int64_t less = 0, equal = 0;
    for (size_t j = 0; j < count; ++j) {
        if (samples[j] < samples[index]) ++less;
        if (samples[j] == samples[index]) ++equal;
    }
    return (double)less + ((double)equal + 1.0) / 2.0;
}

double spearman_average_rank_correlation(const int64_t *values, size_t length) {
    if (values == NULL || length < 5 || length > 257) return INVALID_RESULT;
    int64_t count = values[0];
    if (count < 2 || count > 128 || length != 1 + 2 * (size_t)count) return INVALID_RESULT;
    size_t n = (size_t)count;
    const int64_t *x_values = values + 1;
    const int64_t *y_values = values + 1 + n;
    for (size_t i = 0; i < 2 * n; ++i)
        if (values[1 + i] < -1000000 || values[1 + i] > 1000000) return INVALID_RESULT;
    double mean_rank = ((double)n + 1.0) / 2.0;
    double covariance = 0.0, variance_x = 0.0, variance_y = 0.0;
    for (size_t i = 0; i < n; ++i) {
        double dx = average_rank(x_values, n, i) - mean_rank;
        double dy = average_rank(y_values, n, i) - mean_rank;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x == 0.0 || variance_y == 0.0) return INVALID_RESULT;
    return covariance / sqrt(variance_x * variance_y);
}
