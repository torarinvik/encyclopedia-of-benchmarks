/* Check whether n is the product of two consecutive nonnegative integers. */
#include <math.h>
#include <stdint.h>

int64_t pronic_number(int64_t n)
{
    if (n < 0 || n > INT32_MAX) return -1;
    const int64_t root = (int64_t)sqrt((double)n);
    return root * (root + 1) == n ? 1 : 0;
}
