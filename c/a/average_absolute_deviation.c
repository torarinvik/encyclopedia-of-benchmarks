#include <stddef.h>
#include <stdint.h>
#define MAX_LENGTH 256
#define MIN_VALUE INT64_C(-2147483648)
#define MAX_VALUE INT64_C(2147483647)
#define INVALID_RESULT (-1.0e300)
double average_absolute_deviation(const int64_t *values, size_t length) {
    if (values == NULL || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    double sum = 0.0;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < MIN_VALUE || values[i] > MAX_VALUE) return INVALID_RESULT;
        sum += (double)values[i];
    }
    const double average = sum / (double)length;
    double deviations = 0.0;
    for (size_t i = 0; i < length; ++i) {
        const double value = (double)values[i];
        deviations += value >= average ? value - average : average - value;
    }
    return deviations / (double)length;
}
