/* Independent portable implementation of TheAlgorithms/C odd-even sort. */
#include <stddef.h>
#include <stdint.h>

void odd_even_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    int swapped = 1;
    while (swapped) {
        swapped = 0;
        for (size_t index = 0; index + 1 < length; index += 2) {
            if (values[index] > values[index + 1]) {
                const int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = 1;
            }
        }
        for (size_t index = 1; index + 1 < length; index += 2) {
            if (values[index] > values[index + 1]) {
                const int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = 1;
            }
        }
    }
}
