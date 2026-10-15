/* Return the first lowercase ASCII letter whose frequency is one. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024
#define INVALID_RESULT (-2)

int64_t first_unique_character(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return INVALID_RESULT;
    size_t counts[26] = {0};
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 'a' || values[i] > 'z') return INVALID_RESULT;
        ++counts[(size_t)(values[i] - 'a')];
    }
    for (size_t i = 0; i < length; ++i)
        if (counts[(size_t)(values[i] - 'a')] == 1) return (int64_t)i;
    return -1;
}
