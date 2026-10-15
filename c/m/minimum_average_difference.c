/* Return the earliest split with the smallest difference of integer averages. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 100000
#define MAX_VALUE 100000

int64_t minimum_average_difference(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1;
    int64_t total_sum = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > MAX_VALUE) return -1;
        total_sum += values[index];
    }

    int64_t prefix_sum = 0;
    int64_t best_difference = INT64_MAX;
    size_t best_index = 0;
    for (size_t index = 0; index < length; ++index) {
        prefix_sum += values[index];
        const int64_t left_average = prefix_sum / (int64_t)(index + 1);
        const size_t suffix_length = length - index - 1;
        const int64_t right_average = suffix_length == 0 ? 0
            : (total_sum - prefix_sum) / (int64_t)suffix_length;
        const int64_t difference = left_average >= right_average
            ? left_average - right_average : right_average - left_average;
        if (difference < best_difference) {
            best_difference = difference;
            best_index = index;
        }
    }
    return (int64_t)best_index;
}
