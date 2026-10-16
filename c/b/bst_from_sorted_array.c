#include <stddef.h>
#include <stdint.h>

static uint64_t bst_shape(size_t start, size_t end, size_t heap_index)
{
    if (start >= end) return 0;
    const size_t middle = start + (end - start - 1) / 2;
    return (UINT64_C(1) << heap_index)
         | bst_shape(start, middle, 2 * heap_index + 1)
         | bst_shape(middle + 1, end, 2 * heap_index + 2);
}

int64_t bst_from_sorted_array(const int64_t *values, size_t length)
{
    if (length > 15 || (length != 0 && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
        if (index != 0 && values[index - 1] >= values[index]) return -1;
    }
    return (int64_t)bst_shape(0, length, 0);
}
