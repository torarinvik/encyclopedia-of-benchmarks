#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t is_sorted(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < -INT64_C(2147483648) || values[index] > INT64_C(2147483647)) return -1;
    }
    for (size_t index = 1; index < length; ++index) {
        if (values[index] < values[index - 1]) return 0;
    }
    return 1;
}
