#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024

int64_t maximum_subarray_allow_empty(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length > 0 && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
    }
    int64_t current = 0;
    int64_t best = 0;
    for (size_t index = 0; index < length; ++index) {
        current += values[index];
        if (current < 0) current = 0;
        if (current > best) best = current;
    }
    return best;
}
