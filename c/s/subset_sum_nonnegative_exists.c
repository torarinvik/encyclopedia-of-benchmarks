/* Nonnegative subset existence with descending dynamic programming. */
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define MAX_ITEMS 64
#define MAX_TARGET 4096
#define WIDTH (MAX_TARGET + 1)

int64_t subset_sum_nonnegative_exists(const int64_t *input, size_t length)
{
    if (input == NULL || length == 0 || length > MAX_ITEMS + 1) return -1;
    const int64_t target = input[0];
    if (target < 0 || target > MAX_TARGET) return -1;
    for (size_t i = 1; i < length; ++i)
        if (input[i] < 0 || input[i] > MAX_TARGET) return -1;

    bool reachable[WIDTH] = {false};
    reachable[0] = true;
    for (size_t i = 1; i < length; ++i) {
        const int64_t item = input[i];
        for (int64_t sum = target; sum >= item; --sum)
            if (reachable[(size_t)(sum - item)]) reachable[(size_t)sum] = true;
    }
    return reachable[(size_t)target] ? 1 : 0;
}
