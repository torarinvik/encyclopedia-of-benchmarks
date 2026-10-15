#include <stddef.h>
#include <stdint.h>

int64_t hash_xor8(const int64_t *values, size_t length)
{
    if ((values == NULL && length != 0) || length > 100001) return -1;
    for (size_t i = 0; i < length && values[i] != 0; ++i)
        if (values[i] < 0 || values[i] > 127) return -1;
    uint32_t hash = 0;
    for (size_t i = 0; i < length && values[i] != 0; ++i)
        hash = (hash + (uint32_t)values[i]) & 0xffu;
    return (int64_t)(((hash ^ 0xffu) + 1u) & 0xffu);
}
