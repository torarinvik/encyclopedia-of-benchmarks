/* Remainder check from the pinned JavaScript and TypeScript sources. */
#include <stdint.h>

int64_t is_divisible(uint64_t dividend, uint64_t divisor)
{
    if (dividend > 1000000000 || divisor == 0 || divisor > 1000000000) return -1;
    return dividend % divisor == 0 ? 1 : 0;
}
