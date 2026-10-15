/* Clear low set bits from the upper endpoint until it meets the lower endpoint. */
#include <stdint.h>

int64_t range_bitwise_and(uint64_t left, uint64_t right)
{
    if (left > right || right > UINT64_C(2147483647)) return -1;
    while (left < right) right &= right - UINT64_C(1);
    return (int64_t)right;
}
