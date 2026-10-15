/* Return 1 when a nonnegative integer has an even popcount. */
#include <stdint.h>

int64_t evil_number(int64_t value)
{
    if (value < 0) return -1;
    int64_t count = 0;
    while (value > 0) {
        count += value & 1;
        value >>= 1;
    }
    return count % 2 == 0 ? 1 : 0;
}
