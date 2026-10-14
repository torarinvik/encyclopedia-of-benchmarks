/* Return 1 when n is a positive power of two, otherwise 0. */
#include <stdint.h>

int64_t power_of_two(int64_t n)
{
    if (n <= 0) return 0;
    return (n & (n - 1)) == 0;
}
