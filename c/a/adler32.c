#include <stddef.h>
#include <stdint.h>

int64_t adler32(const int64_t *values, size_t length)
{
    if (length > 100001 || (length != 0 && values == NULL)) return -1;

    uint32_t a = 1;
    uint32_t b = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < 0 || value > 255) return -1;
        a = (a + (uint32_t)value) % UINT32_C(65521);
        b = (b + a) % UINT32_C(65521);
    }

    return (int64_t)((b << 16) | a);
}
