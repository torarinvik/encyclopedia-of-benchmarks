/* Return the unique mode of a bounded integer sequence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define MIN_VALUE 0
#define MAX_VALUE 1000

int64_t average_mode(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > MAX_LENGTH) return -1;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < MIN_VALUE || values[i] > MAX_VALUE) return -1;

    int64_t mode = -1;
    size_t maximum_count = 0;
    int tied = 0;
    for (size_t i = 0; i < length; ++i) {
        int seen = 0;
        for (size_t before = 0; before < i; ++before)
            if (values[before] == values[i]) { seen = 1; break; }
        if (seen) continue;

        size_t count = 0;
        for (size_t j = 0; j < length; ++j)
            if (values[j] == values[i]) ++count;
        if (count > maximum_count) {
            maximum_count = count;
            mode = values[i];
            tied = 0;
        } else if (count == maximum_count) {
            tied = 1;
        }
    }
    return tied ? -1 : mode;
}
