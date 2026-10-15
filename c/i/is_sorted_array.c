#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 100000
#define MAX_SAFE_INTEGER INT64_C(9007199254740991)

int64_t is_sorted_array(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < -MAX_SAFE_INTEGER || values[i] > MAX_SAFE_INTEGER) return -1;
    for (size_t i = 0; i + 1 < length; ++i)
        if (values[i] >= values[i + 1]) return 0;
    return 1;
}
