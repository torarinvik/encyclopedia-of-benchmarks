/* Dark sort: counting sort for nonnegative keys in [0, 128]. */
#include <stddef.h>
#include <stdint.h>

void dark_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    int64_t maximum = values[0];
    for (size_t i = 1; i < length; ++i) if (values[i] > maximum) maximum = values[i];
    int64_t counts[129] = {0};
    for (size_t i = 0; i < length; ++i) ++counts[(size_t)values[i]];
    size_t output = 0;
    for (int64_t value = 0; value <= maximum; ++value)
        while (counts[(size_t)value]-- > 0) values[output++] = value;
}
