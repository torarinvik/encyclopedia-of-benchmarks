#include <stdint.h>

#define INT32_MIN_VALUE (-INT64_C(2147483648))
#define INT32_MAX_VALUE INT64_C(2147483647)

/* Return the trailing-zero count of the signed 32-bit XOR. */
int64_t first_different_bit(int64_t x, int64_t y)
{
    if (x < INT32_MIN_VALUE || x > INT32_MAX_VALUE ||
        y < INT32_MIN_VALUE || y > INT32_MAX_VALUE) return -1;
    uint32_t difference = (uint32_t)(int32_t)x ^ (uint32_t)(int32_t)y;
    int64_t index = 0;
    while (index < 32 && (difference & UINT32_C(1)) == 0) {
        ++index;
        difference >>= 1;
    }
    return index;
}
