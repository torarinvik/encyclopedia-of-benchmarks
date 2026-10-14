/* Independent portable implementation of TheAlgorithms/C pancake sort. */
#include <stddef.h>
#include <stdint.h>

static void flip_prefix(int64_t *values, size_t last)
{
    size_t first = 0;
    while (first < last) {
        const int64_t temporary = values[first];
        values[first] = values[last];
        values[last] = temporary;
        ++first;
        --last;
    }
}

void pancake_sort(int64_t *values, size_t length)
{
    for (size_t prefix = length; prefix > 1; --prefix) {
        size_t maximum = 0;
        for (size_t probe = 1; probe < prefix; ++probe) {
            if (values[probe] > values[maximum]) maximum = probe;
        }
        if (maximum != prefix - 1) {
            flip_prefix(values, maximum);
            flip_prefix(values, prefix - 1);
        }
    }
}
