#include <stdint.h>

int64_t problem1(int64_t limit)
{
    if (limit < 0 || limit > 100000) return -1;
    int64_t sum = 0;
    for (int64_t value = 1; value < limit; ++value)
        if (value % 3 == 0 || value % 5 == 0) sum += value;
    return sum;
}
