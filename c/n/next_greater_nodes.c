/* Brute-force next-greater-value search for each node in list order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODE_COUNT 4096

int64_t next_greater_nodes(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > MAX_NODE_COUNT || values == NULL) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 1 || values[index] > 1000000000) return -1;
    if (output_capacity < 4 * length || output == NULL) return -2;
    for (size_t index = 0; index < length; ++index) {
        int64_t next_greater = 0;
        for (size_t later = index + 1; later < length; ++later) {
            if (values[later] > values[index]) {
                next_greater = values[later];
                break;
            }
        }
        const uint32_t encoded = (uint32_t)next_greater;
        output[4 * index] = (uint8_t)(encoded & UINT32_C(0xff));
        output[4 * index + 1] = (uint8_t)((encoded >> 8) & UINT32_C(0xff));
        output[4 * index + 2] = (uint8_t)((encoded >> 16) & UINT32_C(0xff));
        output[4 * index + 3] = (uint8_t)((encoded >> 24) & UINT32_C(0xff));
    }
    return (int64_t)length;
}
