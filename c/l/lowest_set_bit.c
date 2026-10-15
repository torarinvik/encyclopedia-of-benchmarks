/* Return the isolated least significant set bit. */
#include <stdint.h>

int64_t lowest_set_bit(int64_t value)
{
    if (value < 0 || value > INT32_MAX) return -1;
    return value & -value;
}
