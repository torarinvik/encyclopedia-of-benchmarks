#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define MAX_ABS_VALUE INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double standard_deviation(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double sum = 0.0;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += (double)values[i];
    }
    const double average = sum / (double)length;
    double squared_deviations = 0.0;
    for (size_t i = 0; i < length; ++i) {
        const double difference = (double)values[i] - average;
        squared_deviations += pow(difference, 2.0);
    }
    return sqrt(squared_deviations / (double)length);
}
