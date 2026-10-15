/* Return the longest strictly increasing contiguous run. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 10000

int64_t longest_continuous_increasing_subsequence(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    if (length == 0) return 0;

    size_t current = 1, best = 1;
    for (size_t index = 1; index < length; ++index) {
        if (values[index] > values[index - 1]) ++current;
        else current = 1;
        if (current > best) best = current;
    }
    return (int64_t)best;
}
