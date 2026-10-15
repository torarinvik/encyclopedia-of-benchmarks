/* Return the longest run of ones in a binary array. */
#include <stddef.h>
#include <stdint.h>

int64_t max_consecutive_ones(const int64_t *values, size_t length)
{
    if (length > 4096) return -1;
    size_t best = 0;
    size_t run = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] != 0 && values[index] != 1) return -1;
        if (values[index] == 1) {
            ++run;
            if (run > best) best = run;
        } else {
            run = 0;
        }
    }
    return (int64_t)best;
}
