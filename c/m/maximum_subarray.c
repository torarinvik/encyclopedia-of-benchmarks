/* Kadane's maximum nonempty contiguous-subarray sum. */
#include <stddef.h>
#include <stdint.h>

int64_t maximum_subarray(const int64_t *values, size_t length)
{
    if (length == 0 || length > 1024) return -1;
    int64_t current = values[0];
    int64_t best = current;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
    }
    for (size_t index = 1; index < length; ++index) {
        current = current > 0 ? current + values[index] : values[index];
        if (current > best) best = current;
    }
    return best;
}
