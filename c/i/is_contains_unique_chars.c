#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t is_contains_unique_chars(const int64_t *values, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < 0 || values[i] > 127) return -1;

    uint64_t seen[2] = {0, 0};
    for (size_t i = 0; i < length; ++i) {
        const uint64_t value = (uint64_t)values[i];
        const size_t word = (size_t)(value / 64);
        const uint64_t mask = UINT64_C(1) << (value % 64);
        if ((seen[word] & mask) != 0) return 0;
        seen[word] |= mask;
    }
    return 1;
}
