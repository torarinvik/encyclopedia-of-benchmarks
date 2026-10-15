/* Recursive subtraction-based Euclidean GCD on a bounded positive domain. */
#include <stdint.h>

static int64_t gcd_recursive_euclidean_step(uint64_t left, uint64_t right)
{
    if (left == right) {
        return (int64_t)left;
    }
    if (left > right) {
        return gcd_recursive_euclidean_step(left - right, right);
    }
    return gcd_recursive_euclidean_step(left, right - left);
}

int64_t gcd_recursive_euclidean(uint64_t left, uint64_t right)
{
    if (left == 0 || right == 0 || left > 128 || right > 128) {
        return -1;
    }
    return gcd_recursive_euclidean_step(left, right);
}
