/* Count positions where the prefix sum is at least the remaining suffix sum. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 100000
#define MAX_VALUE 100000

int64_t ways_to_split_array(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_LENGTH) return -1;
    int64_t total_sum = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < -MAX_VALUE || values[index] > MAX_VALUE) return -1;
        total_sum += values[index];
    }
    int64_t prefix_sum = 0;
    int64_t ways = 0;
    for (size_t index = 0; index + 1 < length; ++index) {
        prefix_sum += values[index];
        if (prefix_sum >= total_sum - prefix_sum) ++ways;
    }
    return ways;
}
