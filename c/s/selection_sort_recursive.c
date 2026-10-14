/* Recursive selection sort for the shared signed 64-bit benchmark contract. */
#include <stddef.h>
#include <stdint.h>

static size_t minimum_index(const int64_t *values, size_t start, size_t end)
{
    if (start + 1 >= end) return start;
    const size_t minimum = minimum_index(values, start + 1, end);
    return values[start] < values[minimum] ? start : minimum;
}

static void selection_sort_range(int64_t *values, size_t start, size_t length)
{
    if (start + 1 >= length) return;
    const size_t minimum = minimum_index(values, start, length);
    if (minimum != start) {
        const int64_t temporary = values[start];
        values[start] = values[minimum];
        values[minimum] = temporary;
    }
    selection_sort_range(values, start + 1, length);
}

void selection_sort_recursive(int64_t *values, size_t length)
{
    selection_sort_range(values, 0, length);
}
