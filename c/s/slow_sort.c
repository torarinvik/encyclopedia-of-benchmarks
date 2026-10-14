/* SlowSort over an inclusive interval, following the Java source contract. */
#include <stddef.h>
#include <stdint.h>

static void slow_sort_range(int64_t *values, size_t first, size_t last)
{
    if (first >= last) return;
    const size_t middle = first + (last - first) / 2;
    slow_sort_range(values, first, middle);
    slow_sort_range(values, middle + 1, last);
    if (values[last] < values[middle]) {
        const int64_t temporary = values[last];
        values[last] = values[middle];
        values[middle] = temporary;
    }
    slow_sort_range(values, first, last - 1);
}

void slow_sort(int64_t *values, size_t length)
{
    if (length > 1) slow_sort_range(values, 0, length - 1);
}
