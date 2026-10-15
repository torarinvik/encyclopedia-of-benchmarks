/* Reduce the input array to its minimum with a sign-bit mask. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096
#define MAX_VALUE INT64_C(2147483647)

int64_t bitwisemin(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1;
    int64_t minimum = values[0];
    if (minimum < 0 || minimum > MAX_VALUE) return -1;
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = values[index];
        if (value < 0 || value > MAX_VALUE) return -1;
        const int64_t difference = minimum - value;
        const uint32_t keep_minimum = 0U - (((uint32_t)difference >> 31) & 1U);
        minimum = (int64_t)(((uint32_t)minimum & keep_minimum) |
                            ((uint32_t)value & ~keep_minimum));
    }
    return minimum;
}
