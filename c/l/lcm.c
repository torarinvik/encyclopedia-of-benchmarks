/* Portable LCM with overflow checked after dividing by the GCD. */
#include <stdint.h>

int64_t lcm(uint64_t left, uint64_t right)
{
    if (left == 0 || right == 0) return 0;
    uint64_t a = left, b = right;
    while (b != 0) {
        const uint64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    const uint64_t reduced = left / a;
    if (reduced > UINT64_C(9223372036854775807) / right) return -1;
    return (int64_t)(reduced * right);
}
