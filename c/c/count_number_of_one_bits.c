/* Compare three source-provided methods for counting 32-bit set bits. */
#include <stddef.h>
#include <stdint.h>

#define MAX_U32 UINT64_C(4294967295)

int64_t count_number_of_one_bits(int64_t number, int64_t method)
{
    if (number < 0 || (uint64_t)number > MAX_U32 || method < 0 || method > 2) return -1;
    uint32_t remaining = (uint32_t)number;
    int64_t count = 0;
    if (method == 0) {
        while (remaining != 0) {
            remaining &= remaining - 1;
            ++count;
        }
        return count;
    }
    if (method == 1) {
        while (remaining != 0) {
            if ((remaining % 2U) == 1U) ++count;
            remaining >>= 1;
        }
        return count;
    }
    int64_t lookup[256];
    lookup[0] = 0;
    for (size_t index = 1; index < 256; ++index)
        lookup[index] = lookup[index >> 1] + (int64_t)(index & 1U);
    return lookup[remaining & 0xffU] + lookup[(remaining >> 8) & 0xffU]
         + lookup[(remaining >> 16) & 0xffU] + lookup[(remaining >> 24) & 0xffU];
}
