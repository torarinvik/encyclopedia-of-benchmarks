/* Encode the source divisor list in a lossless positive signed-i64 bit mask. */
#include <stddef.h>
#include <stdint.h>

int64_t divisors(const int64_t *values, size_t length)
{
    if (values == NULL || length != 1) return -1;
    const int64_t n = values[0];
    if (n < 1 || n > 62) return -1;
    uint64_t mask = 0;
    for (int64_t divisor = 1; divisor <= n; ++divisor) {
        if (n % divisor == 0) mask |= UINT64_C(1) << (unsigned)divisor;
    }
    return (int64_t)mask;
}
