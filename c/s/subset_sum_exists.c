/* Decide whether a signed integer subset reaches the requested sum. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define SUBSET_SUM_LIMIT 6144
#define SUBSET_SUM_WIDTH (2 * SUBSET_SUM_LIMIT + 1)
#define SUBSET_SUM_MAX_ITEMS 24

int64_t subset_sum_exists(const int64_t *input, size_t length)
{
    if (length == 0 || length > SUBSET_SUM_MAX_ITEMS + 1) return -1;
    const int64_t target = input[0];
    if (target < -SUBSET_SUM_LIMIT || target > SUBSET_SUM_LIMIT) return -1;
    for (size_t index = 1; index < length; ++index)
        if (input[index] < -256 || input[index] > 256) return -1;

    bool reachable[SUBSET_SUM_WIDTH] = {false};
    reachable[SUBSET_SUM_LIMIT] = true;
    int64_t low = 0, high = 0;
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = input[index];
        if (value > 0) {
            for (int64_t sum = high; sum >= low; --sum)
                if (reachable[sum + SUBSET_SUM_LIMIT])
                    reachable[sum + value + SUBSET_SUM_LIMIT] = true;
            high += value;
        } else if (value < 0) {
            for (int64_t sum = low; sum <= high; ++sum)
                if (reachable[sum + SUBSET_SUM_LIMIT])
                    reachable[sum + value + SUBSET_SUM_LIMIT] = true;
            low += value;
        }
    }
    return reachable[target + SUBSET_SUM_LIMIT] ? 1 : 0;
}
