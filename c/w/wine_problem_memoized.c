#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define MAX_PRICE INT64_C(1000000)

static int64_t solve(const int64_t *prices, size_t count, size_t first, size_t last,
                     int64_t *memo) {
    const size_t slot = first * MAX_ITEMS + last;
    const int64_t year = (int64_t)(count - (last - first + 1) + 1);
    if (first == last) {
        memo[slot] = prices[first] * year;
        return memo[slot];
    }
    if (memo[slot] != 0) return memo[slot];
    const int64_t sell_first = prices[first] * year + solve(prices, count, first + 1, last, memo);
    const int64_t sell_last = prices[last] * year + solve(prices, count, first, last - 1, memo);
    memo[slot] = sell_first > sell_last ? sell_first : sell_last;
    return memo[slot];
}

int64_t wine_problem_memoized(const int64_t *prices, size_t length) {
    if (prices == NULL || length == 0 || length > MAX_ITEMS) return -1;
    for (size_t index = 0; index < length; ++index)
        if (prices[index] < 1 || prices[index] > MAX_PRICE) return -1;
    int64_t memo[MAX_ITEMS * MAX_ITEMS] = {0};
    return solve(prices, length, 0, length - 1, memo);
}
