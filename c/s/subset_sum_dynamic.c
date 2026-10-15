/* Memoized top-down subset existence for signed values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 16
#define OFFSET 400
#define WIDTH 801
#define STATES ((MAX_ITEMS + 1) * WIDTH)

static int64_t search(const int64_t *input, size_t item_count, size_t index,
                      int64_t remaining, int64_t *memo)
{
    if (remaining == 0) return 1;
    if (index == item_count) return 0;
    const size_t state = index * WIDTH + (size_t)(remaining + OFFSET);
    if (memo[state] != -2) return memo[state];
    int64_t result = search(input, item_count, index + 1,
                            remaining - input[index + 1], memo);
    if (result == 0) result = search(input, item_count, index + 1, remaining, memo);
    memo[state] = result;
    return result;
}

int64_t subset_sum_dynamic(const int64_t *input, size_t length)
{
    if (input == NULL || length == 0 || length > MAX_ITEMS + 1) return -1;
    const int64_t target = input[0];
    if (target < -80 || target > 80) return -1;
    for (size_t i = 1; i < length; ++i)
        if (input[i] < -20 || input[i] > 20) return -1;
    int64_t memo[STATES];
    for (size_t i = 0; i < STATES; ++i) memo[i] = -2;
    return search(input, length - 1, 0, target, memo);
}
