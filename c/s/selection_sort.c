/* Independent portable implementation of TheAlgorithms/C selection sort. */
#include <stddef.h>
#include <stdint.h>

void selection_sort(int64_t *values, size_t length)
{
    for (size_t index = 0; index + 1 < length; ++index) {
        size_t minimum = index;
        for (size_t probe = index + 1; probe < length; ++probe) {
            if (values[probe] < values[minimum]) {
                minimum = probe;
            }
        }
        if (minimum != index) {
            const int64_t temporary = values[index];
            values[index] = values[minimum];
            values[minimum] = temporary;
        }
    }
}
