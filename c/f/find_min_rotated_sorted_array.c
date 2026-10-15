#include <stddef.h>
#include <stdint.h>

int64_t find_min_rotated_sorted_array(const int64_t *values, size_t length) {
    if (length < 1 || length > 256 || values == NULL) return -1;
    size_t low = 0;
    size_t high = length - 1;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (values[middle] <= values[high]) high = middle;
        else low = middle + 1;
    }
    return values[low];
}
