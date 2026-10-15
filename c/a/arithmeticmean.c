/* Overflow-safe floor arithmetic mean using the bitwise identity. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALUE INT64_C(9000000000000000000)

int64_t arithmeticmean(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return -1;
    const int64_t left = values[0];
    const int64_t right = values[1];
    if (left < 0 || left > MAX_VALUE || right < 0 || right > MAX_VALUE) return -1;
    return ((left ^ right) >> 1) + (left & right);
}
