/* Mean absolute error over paired prediction and actual arrays. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256
#define INVALID_RESULT (-1.0e300)

double mean_absolute_error_loss(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > 2 * MAX_LENGTH + 1) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_LENGTH || length != 2 * (size_t)count_value + 1)
        return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    double absolute_sum = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t predicted = values[index + 1];
        const int64_t actual = values[index + 1 + count];
        if (predicted < -1000000 || predicted > 1000000 || actual < -1000000 || actual > 1000000)
            return INVALID_RESULT;
        double difference = (double)(predicted - actual);
        if (difference < 0.0) difference = -difference;
        absolute_sum += difference;
    }
    return absolute_sum / (double)count;
}
