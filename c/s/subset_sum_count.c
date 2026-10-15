/* Count indexed signed subsets that reach the requested sum. */
#include <stddef.h>
#include <stdint.h>

#define SUBSET_SUM_LIMIT 6144
#define SUBSET_SUM_WIDTH (2 * SUBSET_SUM_LIMIT + 1)

int64_t subset_sum_count(const int64_t *input, size_t length)
{
    if (length == 0 || length > 25) return -1;
    const int64_t target = input[0];
    if (target < -SUBSET_SUM_LIMIT || target > SUBSET_SUM_LIMIT) return -1;
    for (size_t index = 1; index < length; ++index)
        if (input[index] < -256 || input[index] > 256) return -1;

    int64_t ways[SUBSET_SUM_WIDTH] = {0};
    ways[SUBSET_SUM_LIMIT] = 1;
    int64_t low = 0, high = 0;
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = input[index];
        if (value > 0) {
            for (int64_t sum = high; sum >= low; --sum)
                ways[sum + value + SUBSET_SUM_LIMIT] += ways[sum + SUBSET_SUM_LIMIT];
            high += value;
        } else if (value < 0) {
            for (int64_t sum = low; sum <= high; ++sum)
                ways[sum + value + SUBSET_SUM_LIMIT] += ways[sum + SUBSET_SUM_LIMIT];
            low += value;
        } else {
            for (int64_t sum = low; sum <= high; ++sum)
                ways[sum + SUBSET_SUM_LIMIT] *= 2;
        }
    }
    return ways[target + SUBSET_SUM_LIMIT];
}
