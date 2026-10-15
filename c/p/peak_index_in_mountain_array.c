/* Find the peak of a strict mountain array with binary search. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 100000

int64_t peak_index_in_mountain_array(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_ARRAY_LENGTH) return -1;
    size_t low = 0, high = length - 1;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (values[middle] < values[middle + 1]) low = middle + 1;
        else high = middle;
    }
    if (low == 0 || low + 1 == length) return -1;
    return (int64_t)low;
}
