#include <stdint.h>

static int64_t proper_divisor_sum(int64_t value)
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

int64_t problem21_pair_sum(int64_t limit)
{
    if (limit < 2 || limit > 10000) return -1;
    int64_t total = 0;
    for (int64_t smaller = 2; smaller < limit; ++smaller) {
        const int64_t larger = proper_divisor_sum(smaller);
        if (larger > smaller && proper_divisor_sum(larger) == smaller) {
            total += smaller + larger;
        }
    }
    return total;
}
