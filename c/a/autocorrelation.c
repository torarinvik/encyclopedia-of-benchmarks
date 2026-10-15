/* Biased autocorrelation with variance and covariance divided by n. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define INVALID_RESULT (-1.0e300)

double autocorrelation(const int64_t *values, size_t length)
{
    if (values == NULL || length < 4 || length > MAX_LENGTH + 2) return INVALID_RESULT;
    const int64_t count_value = values[0];
    const int64_t lag_value = values[1];
    if (count_value < 2 || count_value > MAX_LENGTH || length != (size_t)count_value + 2 ||
        lag_value < 0 || lag_value >= count_value) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    const size_t lag = (size_t)lag_value;
    double sum = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = values[index + 2];
        if (value < -1000 || value > 1000) return INVALID_RESULT;
        sum += (double)value;
    }
    const double mean = sum / (double)count;
    double variance_sum = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const double difference = (double)values[index + 2] - mean;
        variance_sum += difference * difference;
    }
    if (variance_sum == 0.0) return INVALID_RESULT;
    const double variance = variance_sum / (double)count;
    double covariance_sum = 0.0;
    for (size_t index = lag; index < count; ++index) {
        const double current = (double)values[index + 2] - mean;
        const double delayed = (double)values[index - lag + 2] - mean;
        covariance_sum += current * delayed;
    }
    const double covariance = covariance_sum / (double)count;
    return covariance / variance;
}
