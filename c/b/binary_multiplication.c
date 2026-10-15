/* Multiply nonnegative operands with shift-and-add; inputs are at most 1e9. */
#include <stdint.h>

int64_t binary_multiplication(uint64_t a, uint64_t b)
{
    uint64_t result = 0;
    while (b > 0) {
        if ((b & 1U) != 0) {
            result += a;
        }
        a += a;
        b >>= 1;
    }
    return (int64_t)result;
}
