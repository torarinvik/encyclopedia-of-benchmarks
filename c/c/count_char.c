#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t count_char(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    int64_t count = 0;
    for (size_t i = 0; i < length; ++i) {
        const int64_t code = values[i];
        if (code < 0 || code > 127) return -1;
        if (code != 9 && code != 10 && code != 11 && code != 12 && code != 13 && code != 32)
            ++count;
    }
    return count;
}
