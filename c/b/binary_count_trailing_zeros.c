/* Count low-order zero bits. */
#include <stdint.h>

int64_t binary_count_trailing_zeros(int64_t n)
{
    if (n <= 0) return n < 0 ? -1 : 0;
    return __builtin_ctzll((uint64_t)n);
}
