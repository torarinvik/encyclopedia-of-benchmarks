/* Portable last-pivot quicksort; recursion is limited to the smaller side. */
#include <stddef.h>
#include <stdint.h>

static size_t partition(int64_t *values, size_t low, size_t high)
{
    const int64_t pivot = values[high - 1];
    size_t boundary = low;
    for (size_t scan = low; scan < high - 1; ++scan) {
        if (values[scan] <= pivot) {
            const int64_t temporary = values[boundary];
            values[boundary] = values[scan];
            values[scan] = temporary;
            ++boundary;
        }
    }
    const int64_t temporary = values[boundary];
    values[boundary] = values[high - 1];
    values[high - 1] = temporary;
    return boundary;
}

static void quick_sort_range(int64_t *values, size_t low, size_t high)
{
    while (high - low > 1) {
        const size_t pivot = partition(values, low, high);
        const size_t right_start = pivot + 1;
        if (pivot - low < high - right_start) {
            quick_sort_range(values, low, pivot);
            low = right_start;
        } else {
            quick_sort_range(values, right_start, high);
            high = pivot;
        }
    }
}

void quick_sort(int64_t *values, size_t length)
{
    if (length > 1) quick_sort_range(values, 0, length);
}
