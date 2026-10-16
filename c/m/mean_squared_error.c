/* Mean squared error over bounded fixed-point samples. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT INT64_C(256)
#define MAX_PARSED_COUNT INT64_C(257)
#define MAX_SAMPLE INT64_C(1000000)
#define MAX_INPUT_LENGTH 515
#define INVALID_RESULT (-1.0e300)

double mean_squared_error(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_PARSED_COUNT) return INVALID_RESULT;
    if (length != (size_t)(1 + 2 * count_value) || count_value == 0 || count_value > MAX_COUNT)
        return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    for (size_t index = 0; index < count * 2; ++index)
        if (values[1 + index] < -MAX_SAMPLE || values[1 + index] > MAX_SAMPLE) return INVALID_RESULT;

    double total = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const double difference = (double)values[1 + index] / 1000000.0 -
                                  (double)values[1 + count + index] / 1000000.0;
        total += difference * difference;
    }
    return total / (double)count;
}
