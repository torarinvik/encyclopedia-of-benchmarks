/* Iterative bitwise XOR for two nonnegative integers in the exact uint53 range. */
#include <stdint.h>

#define MAX_UINT53 INT64_C(9007199254740991)

int64_t uint53_xor(int64_t left, int64_t right)
{
    if (left < 0 || left > MAX_UINT53 || right < 0 || right > MAX_UINT53) return -1;
    int64_t result = 0;
    int64_t bit = 1;
    while (left != 0 && right != 0) {
        const int64_t left_bit = left % 2;
        const int64_t right_bit = right % 2;
        result += ((left_bit + right_bit) % 2) * bit;
        left = (left - left_bit) / 2;
        right = (right - right_bit) / 2;
        bit *= 2;
    }
    return result + (left + right) * bit;
}
