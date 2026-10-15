/* Complement only the significant binary digits of a nonnegative integer. */
#include <stdint.h>

int64_t bitwise_complement(int64_t n)
{
    if (n < 0 || n > INT32_MAX) return -1;
    if (n == 0) return 1;
    uint64_t value = (uint64_t)n;
    uint64_t mask = 0;
    while (value != 0) {
        mask = (mask << 1) | UINT64_C(1);
        value >>= 1;
    }
    return n ^ (int64_t)mask;
}
