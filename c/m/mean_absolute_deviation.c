/* Mean absolute deviation from the arithmetic mean. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256
#define INVALID_RESULT (-1.0e300)

double mean_absolute_deviation(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_LENGTH + 1) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_LENGTH || length != (size_t)count_value + 1) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    double sum = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = values[index + 1];
        if (value < -1000000 || value > 1000000) return INVALID_RESULT;
        sum += (double)value;
    }
    const double mean = sum / (double)count;
    double absolute_sum = 0.0;
    for (size_t index = 0; index < count; ++index)
        absolute_sum += fabs((double)values[index + 1] - mean);
    return absolute_sum / (double)count;
}
