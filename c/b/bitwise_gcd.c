#include <stdint.h>

static unsigned trailing_zeros(uint64_t value)
{
    unsigned count = 0;
    while ((value & 1u) == 0u) {
        value >>= 1;
        ++count;
    }
    return count;
}

int64_t bitwise_gcd(uint64_t left, uint64_t right)
{
    if (left == 0) return (int64_t)right;
    if (right == 0) return (int64_t)left;

    const unsigned common_twos = trailing_zeros(left | right);
    left >>= trailing_zeros(left);
    while (right != 0) {
        right >>= trailing_zeros(right);
        if (left > right) {
            const uint64_t temp = left;
            left = right;
            right = temp;
        }
        right -= left;
    }
    return (int64_t)(left << common_twos);
}
