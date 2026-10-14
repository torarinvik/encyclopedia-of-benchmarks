/* Independent portable implementation of TheAlgorithms/C bubble sort. */
#include <stddef.h>
#include <stdint.h>

void bubble_sort(int64_t *values, size_t length)
{
    for (size_t end = length; end > 1; --end) {
        int swapped = 0;
        for (size_t index = 0; index + 1 < end; ++index) {
            if (values[index] > values[index + 1]) {
                const int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = 1;
            }
        }
        if (!swapped) {
            break;
        }
    }
}
