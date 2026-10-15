/* Select the larger signed-32-bit nonnegative value with a sign bit. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUE INT64_C(2147483647)

int64_t bitwisemax(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return -1;
    const int64_t left = values[0];
    const int64_t right = values[1];
    if (left < 0 || left > MAX_VALUE || right < 0 || right > MAX_VALUE) return -1;
    const int64_t difference = left - right;
    const uint32_t choose_right = ((uint32_t)difference >> 31) & 1U;
    return left - (int64_t)choose_right * difference;
}
