/* Portable Hamming distance over two unsigned 64-bit values. */
#include <stdint.h>

int64_t hamming_distance(uint64_t left, uint64_t right)
{
    int64_t count = 0;
    while (left != 0 || right != 0) {
        if ((left & UINT64_C(1)) != (right & UINT64_C(1))) ++count;
        left >>= 1;
        right >>= 1;
    }
    return count;
}
