/* Return whether a value is abundant and not semiperfect. */
#include <stdint.h>

int64_t weird_number(int64_t value)
{
    if (value < 0 || value > 512) return -1;
    if (value == 0) return 0;
    uint8_t reachable[513] = {0};
    reachable[0] = 1;
    int64_t divisor_sum = 0;
    for (int64_t divisor = 1; divisor <= value / 2; ++divisor) {
        if (value % divisor != 0) continue;
        divisor_sum += divisor;
        for (int64_t total = value; total >= divisor; --total) {
            if (reachable[total - divisor]) reachable[total] = 1;
        }
    }
    return divisor_sum > value && !reachable[value];
}
