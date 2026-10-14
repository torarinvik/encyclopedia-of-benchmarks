/* Stable bidirectional bubble sort for signed 64-bit values. */
#include <stddef.h>
#include <stdint.h>

void cocktail_sort(int64_t *values, size_t length)
{
    size_t start = 0;
    size_t end = length;
    while (start < end) {
        int swapped = 0;
        for (size_t index = start; index + 1 < end; ++index) {
            if (values[index] > values[index + 1]) {
                const int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = 1;
            }
        }
        if (!swapped) break;
        --end;
        swapped = 0;
        size_t index = end;
        while (index > start) {
            if (values[index - 1] > values[index]) {
                const int64_t temporary = values[index - 1];
                values[index - 1] = values[index];
                values[index] = temporary;
                swapped = 1;
            }
            --index;
        }
        ++start;
        if (!swapped) break;
    }
}
