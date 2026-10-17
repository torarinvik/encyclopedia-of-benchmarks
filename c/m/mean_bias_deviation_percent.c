/* Mean bias deviation percentage over bounded paired integer samples. */
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT INT64_C(64)
#define MAX_PARSED_COUNT INT64_C(65)
#define MAX_SAMPLE INT64_C(1000)
#define MAX_INPUT_LENGTH 131
#define INVALID_RESULT (-1.0e300)

double mean_bias_deviation_percent(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH)
        return INVALID_RESULT;

    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_PARSED_COUNT)
        return INVALID_RESULT;
    if (length != 1 + 2 * (size_t)count_value
            || count_value < 1 || count_value > MAX_COUNT)
        return INVALID_RESULT;

    const size_t count = (size_t)count_value;
    int64_t difference_sum = 0;
    int64_t actual_sum = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t prediction = values[1 + index];
        const int64_t actual = values[1 + count + index];
        if (prediction < -MAX_SAMPLE || prediction > MAX_SAMPLE
                || actual < -MAX_SAMPLE || actual > MAX_SAMPLE)
            return INVALID_RESULT;
        difference_sum += prediction - actual;
        actual_sum += actual;
    }
    if (actual_sum == 0) return INVALID_RESULT;

    const double numerator = (double)difference_sum / (double)count;
    const double denominator = (double)actual_sum / (double)count;
    return numerator / denominator * 100.0;
}
