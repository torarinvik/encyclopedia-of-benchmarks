/* Sign of a signed 64-bit integer. */
#include <stdint.h>

int64_t signum(int64_t value)
{
    return (value > 0) - (value < 0);
}
