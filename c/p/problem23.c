/* Sum positive integers through the limit that are not sums of two abundant numbers. */
#include <stdint.h>

#define MAX_LIMIT 28123

int64_t problem23(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;

    int64_t proper_divisor_sums[MAX_LIMIT + 1] = {0};
    uint8_t abundant[MAX_LIMIT + 1] = {0};
    uint8_t representable[MAX_LIMIT + 1] = {0};
    const int64_t bound = limit;

    for (int64_t divisor = 1; divisor <= bound / 2; ++divisor) {
        for (int64_t multiple = 2 * divisor; multiple <= bound; multiple += divisor) {
            proper_divisor_sums[multiple] += divisor;
        }
    }
    for (int64_t value = 12; value <= bound; ++value) {
        abundant[value] = proper_divisor_sums[value] > value;
    }
    for (int64_t left = 12; left <= bound; ++left) {
        if (!abundant[left]) continue;
        for (int64_t right = left; right <= bound - left; ++right) {
            if (abundant[right]) representable[left + right] = 1;
        }
    }

    int64_t total = 0;
    for (int64_t value = 1; value <= bound; ++value) {
        if (!representable[value]) total += value;
    }
    return total;
}
