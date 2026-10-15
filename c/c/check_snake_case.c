#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t check_snake_case(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -2;
    int64_t found = 0;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 32 || values[i] > 126) return -2;
        if (values[i] == 95) found = 1;
    }
    return found;
}
