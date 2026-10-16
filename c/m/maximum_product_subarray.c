/* Maximum product of a nonempty contiguous subarray. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 9
#define MIN_VALUE (-10LL)
#define MAX_VALUE 10LL
#define INVALID_RESULT INT64_MIN

int64_t maximum_product_subarray(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < MIN_VALUE || values[index] > MAX_VALUE) return INVALID_RESULT;
    }

    int64_t current_max = values[0], current_min = values[0], best = values[0];
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = values[index];
        const int64_t prior_max = current_max;
        const int64_t prior_min = current_min;
        const int64_t from_max = prior_max * value;
        const int64_t from_min = prior_min * value;
        current_max = value > from_max ? (value > from_min ? value : from_min)
                                       : (from_max > from_min ? from_max : from_min);
        current_min = value < from_max ? (value < from_min ? value : from_min)
                                       : (from_max < from_min ? from_max : from_min);
        best = best > current_max ? best : current_max;
    }
    return best;
}
