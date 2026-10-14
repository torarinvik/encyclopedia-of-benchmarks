/* Portable stooge sort using half-open subranges. */
#include <stddef.h>
#include <stdint.h>

static void stooge_sort_range(int64_t *values, size_t low, size_t high)
{
    const size_t length = high - low;
    if (length < 2) return;
    if (values[low] > values[high - 1]) {
        const int64_t temporary = values[low];
        values[low] = values[high - 1];
        values[high - 1] = temporary;
    }
    if (length > 2) {
        const size_t third = length / 3;
        stooge_sort_range(values, low, high - third);
        stooge_sort_range(values, low + third, high);
        stooge_sort_range(values, low, high - third);
    }
}

void stooge_sort(int64_t *values, size_t length)
{
    if (length > 1) stooge_sort_range(values, 0, length);
}
