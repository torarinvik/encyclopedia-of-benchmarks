#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 14
#define MAX_PRICE INT64_C(1000000)

static int64_t solve(const int64_t *prices, size_t count, size_t first, size_t last) {
    const int64_t year = (int64_t)(count - (last - first + 1) + 1);
    if (first == last) return prices[first] * year;
    const int64_t sell_first = prices[first] * year + solve(prices, count, first + 1, last);
    const int64_t sell_last = prices[last] * year + solve(prices, count, first, last - 1);
    return sell_first > sell_last ? sell_first : sell_last;
}

int64_t wine_problem_recursive(const int64_t *prices, size_t length) {
    if (prices == NULL || length == 0 || length > MAX_ITEMS) return -1;
    for (size_t index = 0; index < length; ++index)
        if (prices[index] < 0 || prices[index] > MAX_PRICE) return -1;
    return solve(prices, length, 0, length - 1);
}
