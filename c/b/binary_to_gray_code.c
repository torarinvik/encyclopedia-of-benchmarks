/* Convert a nonnegative integer to its binary-reflected Gray code. */
#include <stdint.h>

int64_t binary_to_gray_code(int64_t value)
{
    if (value < 0) return -1;
    return value ^ (value >> 1);
}
