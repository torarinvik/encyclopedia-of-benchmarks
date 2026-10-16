/* First-element-pivot quicksort using Hoare's partition scheme. */
#include <stddef.h>
#include <stdint.h>

static size_t partition_range(int64_t *values, size_t low, size_t high)
{
    const int64_t pivot = values[low];
    size_t left = low;
    size_t right = high;
    for (;;) {
        while (values[left] < pivot) ++left;
        while (values[right] > pivot) --right;
        if (left >= right) return right;
        const int64_t temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
        ++left;
        --right;
    }
}

static void partition_sort_range(int64_t *values, size_t low, size_t high)
{
    if (low < high) {
        const size_t split = partition_range(values, low, high);
        partition_sort_range(values, low, split);
        partition_sort_range(values, split + 1, high);
    }
}

void partition_sort(int64_t *values, size_t length)
{
    if (length > 1) partition_sort_range(values, 0, length - 1);
}
