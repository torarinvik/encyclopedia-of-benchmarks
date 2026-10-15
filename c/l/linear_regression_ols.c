/* Univariate ordinary least-squares slope for packed integer observations. */
#include <stddef.h>
#include <stdint.h>

#define MAX_OBSERVATIONS 128
#define INVALID_RESULT (-1.0e300)

double linear_regression_ols(const int64_t *values, size_t length)
{
    if (values == NULL || length < 5 || length > 1 + 2 * MAX_OBSERVATIONS || length % 2 == 0) {
        return INVALID_RESULT;
    }
    const int64_t count = values[0];
    if (count < 2 || count > MAX_OBSERVATIONS || length != 1 + 2 * (size_t)count) {
        return INVALID_RESULT;
    }

    double sum_x = 0.0;
    double sum_y = 0.0;
    for (size_t index = 0; index < (size_t)count; ++index) {
        const int64_t x = values[1 + 2 * index];
        const int64_t y = values[2 + 2 * index];
        if (x < -1000000 || x > 1000000 || y < -1000000 || y > 1000000) return INVALID_RESULT;
        sum_x += (double)x;
        sum_y += (double)y;
    }
    const double mean_x = sum_x / (double)count;
    const double mean_y = sum_y / (double)count;
    double covariance = 0.0;
    double variance_x = 0.0;
    double variance_y = 0.0;
    for (size_t index = 0; index < (size_t)count; ++index) {
        const double dx = (double)values[1 + 2 * index] - mean_x;
        const double dy = (double)values[2 + 2 * index] - mean_y;
        covariance += dx * dy;
        variance_x += dx * dx;
        variance_y += dy * dy;
    }
    if (variance_x <= 1e-12 || variance_y <= 1e-12) return INVALID_RESULT;
    return covariance / variance_x;
}
