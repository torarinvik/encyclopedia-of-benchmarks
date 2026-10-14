/* Portable iterative Euclidean GCD for nonnegative signed 64-bit inputs. */
#include <stdint.h>

int64_t gcd(uint64_t left, uint64_t right)
{
    while (right != 0) {
        const uint64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return (int64_t)left;
}
