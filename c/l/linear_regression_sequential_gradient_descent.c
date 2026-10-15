/* Julia-style one-feature gradient descent with sequential slope/intercept updates. */
#include <stddef.h>
#include <stdint.h>

#define MAX_OBSERVATIONS 64
#define MAX_EPOCHS 10000
#define INVALID_RESULT (-1.0e300)

double linear_regression_sequential_gradient_descent(const int64_t *values, size_t length)
{
    if (values == NULL || length < 7 || length > 3 + 2 * MAX_OBSERVATIONS || length % 2 == 0) return INVALID_RESULT;
    const int64_t count = values[0];
    const int64_t rate_microunits = values[1];
    const int64_t epochs = values[2];
    if (count < 2 || count > MAX_OBSERVATIONS || length != 3 + 2 * (size_t)count ||
        rate_microunits < 1 || rate_microunits > 1000 || epochs < 1 || epochs > MAX_EPOCHS) return INVALID_RESULT;
    for (size_t index = 0; index < (size_t)count; ++index) {
        const int64_t x = values[3 + 2 * index];
        const int64_t y = values[4 + 2 * index];
        if (x < -10 || x > 10 || y < -100 || y > 100) return INVALID_RESULT;
    }

    const double alpha = (double)rate_microunits / 1000000.0;
    const double scale = alpha / (double)count;
    double slope = 0.0;
    double intercept = 0.0;
    double cost = 0.0;
    for (int64_t epoch = 0; epoch < epochs; ++epoch) {
        double slope_gradient = 0.0;
        for (size_t index = 0; index < (size_t)count; ++index) {
            const double x = (double)values[3 + 2 * index];
            const double y = (double)values[4 + 2 * index];
            slope_gradient += (slope * x + intercept - y) * x;
        }
        slope -= scale * slope_gradient;

        double intercept_gradient = 0.0;
        for (size_t index = 0; index < (size_t)count; ++index) {
            const double x = (double)values[3 + 2 * index];
            const double y = (double)values[4 + 2 * index];
            intercept_gradient += slope * x + intercept - y;
        }
        intercept -= scale * intercept_gradient;

        cost = 0.0;
        for (size_t index = 0; index < (size_t)count; ++index) {
            const double x = (double)values[3 + 2 * index];
            const double y = (double)values[4 + 2 * index];
            const double error = slope * x + intercept - y;
            cost += error * error;
        }
        cost /= 2.0 * (double)count;
    }
    return cost;
}
