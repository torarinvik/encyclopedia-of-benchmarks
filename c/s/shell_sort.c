/* Independent portable implementation of TheAlgorithms/C shell sort. */
#include <stddef.h>
#include <stdint.h>

void shell_sort(int64_t *values, size_t length)
{
    for (size_t gap = length / 2; gap > 0; gap /= 2) {
        for (size_t index = gap; index < length; ++index) {
            const int64_t key = values[index];
            size_t position = index;
            while (position >= gap && values[position - gap] > key) {
                values[position] = values[position - gap];
                position -= gap;
            }
            values[position] = key;
        }
    }
}
