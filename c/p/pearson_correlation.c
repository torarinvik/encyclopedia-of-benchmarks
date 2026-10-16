#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OBSERVATIONS 128
#define MAX_ABS_VALUE INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double pearson_correlation(const int64_t *values, size_t length) {
    if (values == NULL || length < 5 || length > 1 + 2 * MAX_OBSERVATIONS) return INVALID_RESULT;
    int64_t count = values[0];
    if (count < 2 || count > MAX_OBSERVATIONS || length != 1 + 2 * (size_t)count) return INVALID_RESULT;

    double sum_x = 0.0, sum_y = 0.0;
    for (size_t i = 0; i < (size_t)count; ++i) {
        int64_t x = values[1 + i], y = values[1 + (size_t)count + i];
        if (x < -MAX_ABS_VALUE || x > MAX_ABS_VALUE || y < -MAX_ABS_VALUE || y > MAX_ABS_VALUE) return INVALID_RESULT;
        sum_x += (double)x;
        sum_y += (double)y;
    }
    double mean_x = sum_x / (double)count, mean_y = sum_y / (double)count;
    double covariance = 0.0, variance_x = 0.0, variance_y = 0.0;
    for (size_t i = 0; i < (size_t)count; ++i) {
        double dx = (double)values[1 + i] - mean_x;
        double dy = (double)values[1 + (size_t)count + i] - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x == 0.0 || variance_y == 0.0) return INVALID_RESULT;
    return covariance / sqrt(variance_x * variance_y);
}
