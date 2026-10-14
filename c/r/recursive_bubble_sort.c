/* Recursive bubble sort for the shared signed 64-bit benchmark contract. */
#include <stddef.h>
#include <stdint.h>

static void recursive_bubble_sort_range(int64_t *values, size_t length)
{
    if (length < 2) return;
    for (size_t index = 0; index + 1 < length; ++index) {
        if (values[index] > values[index + 1]) {
            const int64_t temporary = values[index];
            values[index] = values[index + 1];
            values[index + 1] = temporary;
        }
    }
    recursive_bubble_sort_range(values, length - 1);
}

void recursive_bubble_sort(int64_t *values, size_t length)
{
    recursive_bubble_sort_range(values, length);
}
