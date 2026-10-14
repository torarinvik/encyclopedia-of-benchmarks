/* Independent portable implementation of TheAlgorithms/C insertion sort. */
#include <stddef.h>
#include <stdint.h>

void insertion_sort(int64_t *values, size_t length)
{
    for (size_t index = 1; index < length; ++index) {
        const int64_t key = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > key) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = key;
    }
}
