/* Count positions where the prefix sum is at least the remaining suffix sum. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 100000
#define MAX_VALUE 100000

int64_t ways_to_split_array(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_LENGTH) return -1;
    uint64_t total = 0, largest_biased_value = 0;
    for (size_t index = 0; index < length; ++index) {
        const uint64_t value = (uint64_t)values[index];
        const uint64_t biased = value + MAX_VALUE;
        largest_biased_value = biased > largest_biased_value ? biased : largest_biased_value;
        total += value;
    }
    if (largest_biased_value > 2 * MAX_VALUE) return -1;
    const int64_t signed_total = (int64_t)total;
    const int64_t threshold = signed_total / 2 + (signed_total > 0 && signed_total % 2 != 0);
    uint64_t prefix = 0;
    int64_t ways = 0;
    for (size_t index = 0; index < length - 1; ++index) {
        prefix += (uint64_t)values[index];
        if ((int64_t)prefix >= threshold) ways++;
    }
    return ways;
}
