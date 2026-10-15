/* Mean squared error over paired prediction and expected arrays. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256
#define INVALID_RESULT (-1.0e300)

double mean_square_error(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > 2 * MAX_LENGTH + 1) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_LENGTH || length != 2 * (size_t)count_value + 1)
        return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    double error_sum = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t predicted = values[index + 1];
        const int64_t expected = values[index + 1 + count];
        if (predicted < -1000000 || predicted > 1000000 || expected < -1000000 || expected > 1000000)
            return INVALID_RESULT;
        const double difference = (double)(expected - predicted);
        error_sum += difference * difference;
    }
    return error_sum / (double)count;
}
