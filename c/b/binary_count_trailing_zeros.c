/* Count low-order zero bits by shifting away factors of two. */
#include <stdint.h>

int64_t binary_count_trailing_zeros(int64_t n)
{
    if (n < 0) return -1;
    int64_t count = 0;
    while (n > 0 && (n & 1) == 0) {
        n >>= 1;
        ++count;
    }
    return count;
}
