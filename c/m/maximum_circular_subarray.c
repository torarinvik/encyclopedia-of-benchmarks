/* Kadane-based maximum nonempty contiguous circular-subarray sum. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64
#define MIN_VALUE (-1000000LL)
#define MAX_VALUE 1000000LL
#define INVALID_RESULT INT64_MIN

int64_t maximum_circular_subarray(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < MIN_VALUE || values[index] > MAX_VALUE) return INVALID_RESULT;
    }

    int64_t total = values[0];
    int64_t current_max = values[0], max_so_far = values[0];
    int64_t current_min = values[0], min_so_far = values[0];
    for (size_t index = 1; index < length; ++index) {
        int64_t value = values[index];
        total += value;
        current_max = current_max + value > value ? current_max + value : value;
        max_so_far = max_so_far > current_max ? max_so_far : current_max;
        current_min = current_min + value < value ? current_min + value : value;
        min_so_far = min_so_far < current_min ? min_so_far : current_min;
    }
    if (min_so_far == total) return max_so_far;
    return max_so_far > total - min_so_far ? max_so_far : total - min_so_far;
}
