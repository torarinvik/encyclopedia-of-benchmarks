/* Stable binary insertion sort for signed 64-bit values. */
#include <stddef.h>
#include <stdint.h>

void binary_insertion_sort(int64_t *values, size_t length)
{
    for (size_t index = 1; index < length; ++index) {
        const int64_t key = values[index];
        size_t low = 0;
        size_t high = index;
        while (low < high) {
            const size_t middle = low + (high - low) / 2;
            if (values[middle] <= key) low = middle + 1;
            else high = middle;
        }
        size_t position = index;
        while (position > low) {
            values[position] = values[position - 1];
            --position;
        }
        values[low] = key;
    }
}
