#include <stdint.h>

static int64_t problem21_proper_divisor_sum(int64_t value)
{
    if (value <= 1) return 0;
    int64_t sum = 1;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor != 0) continue;
        const int64_t partner = value / divisor;
        sum += divisor;
        if (partner != divisor) sum += partner;
    }
    return sum;
}

int64_t problem21(int64_t limit)
{
    if (limit < 1 || limit > 10000) return -1;
    int64_t total = 0;
    for (int64_t value = 1; value < limit; ++value) {
        const int64_t partner = problem21_proper_divisor_sum(value);
        if (partner != value && problem21_proper_divisor_sum(partner) == value) total += value;
    }
    return total;
}
