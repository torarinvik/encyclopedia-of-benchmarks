#include <stdint.h>

#define MAX_INDEX INT64_C(3037000499)

int64_t squares_sequence(int64_t index)
{
    if (index < 0 || index > MAX_INDEX) return -1;
    return index * index;
}
