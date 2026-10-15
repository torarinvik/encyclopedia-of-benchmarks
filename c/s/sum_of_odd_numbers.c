#include <stdint.h>

int64_t sum_of_odd_numbers(int64_t n)
{
    if (n < 0 || n > 46340) return -1;
    return n * n;
}
