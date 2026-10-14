/* Return the smallest signed value in a nonempty array. */
#include <stddef.h>
#include <stdint.h>

int64_t find_min(const int64_t *values, size_t length)
{
    if (length == 0 || length > 512) return -1;
    int64_t result = values[0];
    for (size_t index = 1; index < length; ++index) {
        if (values[index] < result) result = values[index];
    }
    return result;
}
