/* Add nonnegative integers with XOR and shifted AND carry propagation. */
#include <stdint.h>

int64_t bitwise_addition(uint64_t first, uint64_t second)
{
    while (second != 0) {
        const uint64_t carry = first & second;
        first ^= second;
        second = carry << 1;
    }
    return (int64_t)first;
}
