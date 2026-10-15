#include <stdint.h>

#define INT32_MIN_VALUE (-INT64_C(2147483648))
#define INT32_MAX_VALUE INT64_C(2147483647)

/* Return whether the signed 32-bit XOR has its sign bit set. */
int64_t numbers_different_signs(int64_t left, int64_t right)
{
    if (left < INT32_MIN_VALUE || left > INT32_MAX_VALUE ||
        right < INT32_MIN_VALUE || right > INT32_MAX_VALUE) return -1;
    const int32_t left_value = (int32_t)left;
    const int32_t right_value = (int32_t)right;
    return (left_value ^ right_value) < 0 ? 1 : 0;
}
