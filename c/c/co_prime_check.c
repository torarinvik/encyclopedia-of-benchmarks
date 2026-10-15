/* Return whether two nonnegative int32 values have greatest common divisor one. */
#include <stdint.h>

int64_t co_prime_check(uint64_t first, uint64_t second)
{
    if (first > INT32_MAX || second > INT32_MAX) return -1;
    while (second != 0) {
        const uint64_t remainder = first % second;
        first = second;
        second = remainder;
    }
    return first == 1 ? 1 : 0;
}
