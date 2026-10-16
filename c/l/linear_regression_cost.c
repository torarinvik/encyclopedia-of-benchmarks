#include <stddef.h>
#include <stdint.h>

#define MAX_OBSERVATIONS 64
#define MAX_FEATURES 16
#define MAX_INPUT_LENGTH (2 + MAX_OBSERVATIONS * MAX_FEATURES + MAX_FEATURES + MAX_OBSERVATIONS)
#define INVALID_RESULT (-1.0e300)

double linear_regression_cost(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (values[0] < 1 || values[0] > MAX_OBSERVATIONS ||
        values[1] < 1 || values[1] > MAX_FEATURES) return INVALID_RESULT;
    const size_t observations = (size_t)values[0];
    const size_t features = (size_t)values[1];
    const size_t matrix_length = observations * features;
    if (length != 2 + matrix_length + features + observations) return INVALID_RESULT;
    for (size_t index = 2; index < length; ++index) {
        if (values[index] < -1000 || values[index] > 1000) return INVALID_RESULT;
    }

    const size_t weights_start = 2 + matrix_length;
    const size_t targets_start = weights_start + features;
    double squared_error_sum = 0.0;
    for (size_t row = 0; row < observations; ++row) {
        double prediction = 0.0;
        const size_t row_start = 2 + row * features;
        for (size_t column = 0; column < features; ++column) {
            prediction += (double)values[row_start + column] * (double)values[weights_start + column];
        }
        const double error = prediction - (double)values[targets_start + row];
        squared_error_sum += error * error;
    }
    return squared_error_sum / (2.0 * (double)observations);
}
