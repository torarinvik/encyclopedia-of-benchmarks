#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024
#define MAX_ABS_VALUE INT64_C(1000000)

int64_t maximum_subarray_int32(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < -MAX_ABS_VALUE || values[index] > MAX_ABS_VALUE) return -1;
    }
    int64_t current = values[0];
    int64_t best = current;
    for (size_t index = 1; index < length; ++index) {
        current = current > 0 ? current + values[index] : values[index];
        if (current > best) best = current;
    }
    return best;
}
