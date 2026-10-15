/* Copy positive list values, then scan each mirrored twin pair. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024

int64_t maximum_twin_sum_of_linked_list(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_LENGTH || length % 2 != 0) return -1;
    int32_t copied[MAX_LENGTH];
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 1 || values[index] > 100000) return -1;
        copied[index] = (int32_t)values[index];
    }
    int64_t maximum = 0;
    for (size_t index = 0; index < length / 2; ++index) {
        const int64_t twin_sum = (int64_t)copied[index] + copied[length - index - 1];
        if (twin_sum > maximum) maximum = twin_sum;
    }
    return maximum;
}
