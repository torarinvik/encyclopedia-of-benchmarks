/* Fletcher-16 checksum for bounded ASCII byte arrays. */
#include <stddef.h>
#include <stdint.h>

#define MAX_BYTES 4096

int64_t fletcher16(const int64_t *input, size_t length)
{
    if (length > MAX_BYTES || (length != 0 && input == NULL)) return -1;
    uint32_t sum1 = 0;
    uint32_t sum2 = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t byte = input[index];
        if (byte < 0 || byte > 127) return -1;
        sum1 = (sum1 + (uint32_t)byte) % 255;
        sum2 = (sum2 + sum1) % 255;
    }
    return (int64_t)((sum2 << 8) | sum1);
}
