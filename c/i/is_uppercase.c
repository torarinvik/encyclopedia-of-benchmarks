#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t is_uppercase(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 32 || values[i] > 126) return -1;
        if (values[i] >= 'a' && values[i] <= 'z') return 0;
    }
    return 1;
}
