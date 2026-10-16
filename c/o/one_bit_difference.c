#include <stddef.h>
#include <stdint.h>

int64_t one_bit_difference(const int64_t *input, size_t length)
{
    if (input == NULL || length != 2) return -1;
    const int64_t left = input[0];
    const int64_t right = input[1];
    if (left < INT32_MIN || left > INT32_MAX || right < INT32_MIN || right > INT32_MAX) return -1;
    const uint32_t difference = (uint32_t)(int32_t)left ^ (uint32_t)(int32_t)right;
    return difference != 0 && (difference & (difference - UINT32_C(1))) == 0 ? 1 : 0;
}
