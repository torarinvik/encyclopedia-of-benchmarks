/* Check the bounded ASCII Pascal-case predicate. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t check_pascal_case(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -2;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -2;
    if (length == 0 || values[0] < 'A' || values[0] > 'Z') return 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t value = values[i];
        if (!((value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z'))) return 0;
    }
    return 1;
}
