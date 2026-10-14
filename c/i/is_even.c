/* Return 1 for an even signed 64-bit integer and 0 for an odd one. */
#include <stdint.h>

int64_t is_even(int64_t value)
{
    return value % 2 == 0;
}
