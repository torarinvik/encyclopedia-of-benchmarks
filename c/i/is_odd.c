/* Return 1 for an odd signed 64-bit integer and 0 for an even one. */
#include <stdint.h>

int64_t is_odd(int64_t value)
{
    return value % 2 != 0;
}
