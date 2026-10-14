/* Stable recursive insertion sort over signed 64-bit values. */
#include <stddef.h>
#include <stdint.h>

static void insertion_sort_prefix(int64_t *values, size_t length)
{
    if (length <= 1) return;
    insertion_sort_prefix(values, length - 1);
    const int64_t key = values[length - 1];
    size_t position = length - 1;
    while (position > 0 && values[position - 1] > key) {
        values[position] = values[position - 1];
        --position;
    }
    values[position] = key;
}

void insertion_sort_recursive(int64_t *values, size_t length)
{
    insertion_sort_prefix(values, length);
}
