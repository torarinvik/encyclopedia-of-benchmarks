/* Recursive subtractive greatest common factor from the pinned MATLAB source. */
#include <stdint.h>

static uint64_t highest_common_factor_impl(uint64_t x, uint64_t y)
{
    if (x == 0) return y;
    if (y == 0) return x;
    if (x == y) return x;
    if (y > x) return highest_common_factor_impl(y - x, x);
    return highest_common_factor_impl(x - y, y);
}

int64_t highest_common_factor(uint64_t x, uint64_t y)
{
    return (int64_t)highest_common_factor_impl(x, y);
}
