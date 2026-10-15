#include <stdint.h>

int64_t natural_sequence(int64_t index)
{
    if (index < 0 || index == INT64_MAX) return -1;
    return index + 1;
}
