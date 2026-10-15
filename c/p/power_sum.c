/* Count distinct positive bases whose powers sum to the target. */
#include <stddef.h>
#include <stdint.h>

static int64_t power_sum_search(int64_t target, int64_t power, int64_t base, int64_t current_sum)
{
    int64_t term = 1;
    for (int64_t exponent = 0; exponent < power; ++exponent) term *= base;
    const int64_t new_sum = current_sum + term;
    if (new_sum == target) return 1;
    if (new_sum > target) return 0;
    return power_sum_search(target, power, base + 1, new_sum)
         + power_sum_search(target, power, base + 1, current_sum);
}

int64_t power_sum(const int64_t *packed, size_t length)
{
    if (packed == NULL || length != 2) return -1;
    const int64_t target = packed[0];
    const int64_t power = packed[1];
    if (target < 1 || target > 1000 || power < 2 || power > 10) return -1;
    return power_sum_search(target, power, 1, 0);
}
