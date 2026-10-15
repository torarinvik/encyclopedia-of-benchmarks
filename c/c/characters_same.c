#include <stddef.h>
#include <stdint.h>

int64_t characters_same(const int64_t *values, size_t length)
{
    if (length > 256 || (length != 0 && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 127) return -1;
    if (length == 0) return 1;
    const int64_t first = values[0];
    for (size_t index = 1; index < length; ++index)
        if (values[index] != first) return 0;
    return 1;
}
