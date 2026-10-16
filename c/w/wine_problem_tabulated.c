#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 64
#define MAX_PRICE INT64_C(1000000)

int64_t wine_problem_tabulated(const int64_t *prices, size_t length) {
    if (prices == NULL || length == 0 || length > MAX_ITEMS) return -1;
    for (size_t index = 0; index < length; ++index)
        if (prices[index] < 0 || prices[index] > MAX_PRICE) return -1;
    int64_t table[MAX_ITEMS * MAX_ITEMS] = {0};
    for (size_t width = 1; width <= length; ++width) {
        const int64_t year = (int64_t)(length - width + 1);
        for (size_t first = 0; first + width <= length; ++first) {
            const size_t last = first + width - 1;
            const size_t slot = first * MAX_ITEMS + last;
            if (first == last) {
                table[slot] = prices[first] * year;
            } else {
                const int64_t sell_first = prices[first] * year + table[(first + 1) * MAX_ITEMS + last];
                const int64_t sell_last = prices[last] * year + table[first * MAX_ITEMS + last - 1];
                table[slot] = sell_first > sell_last ? sell_first : sell_last;
            }
        }
    }
    return table[length - 1];
}
