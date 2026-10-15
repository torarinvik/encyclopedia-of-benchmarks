/* Check whether the bounded ASCII input is entirely lowercase letters. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t check_flat_case(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -2;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = values[i];
        if (value < 32 || value > 126) return -2;
    }
    for (size_t i = 0; i < length; ++i)
        if (values[i] < 'a' || values[i] > 'z') return 0;
    return 1;
}
