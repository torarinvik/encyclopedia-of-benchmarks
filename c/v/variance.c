#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define MAX_ABS_VALUE INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double variance(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_LENGTH) return INVALID_RESULT;
    double sum = 0.0;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += (double)values[i];
    }
    const double average = sum / (double)length;
    double squared_deviations = 0.0;
    for (size_t i = 0; i < length; ++i) {
        const double difference = (double)values[i] - average;
        squared_deviations += difference * difference;
    }
    return squared_deviations / (double)(length - 1);
}
