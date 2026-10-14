/* Portable exchange sort for the shared signed 64-bit benchmark contract. */
#include <stddef.h>
#include <stdint.h>

void exchange_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    const size_t last = length - 1;
    for (size_t first = 0; first < last; ++first) {
        for (size_t other = first + 1; other < length; ++other) {
            if (values[other] < values[first]) {
                const int64_t temporary = values[first];
                values[first] = values[other];
                values[other] = temporary;
            }
        }
    }
}
