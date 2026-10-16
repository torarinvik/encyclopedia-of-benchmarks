/* Count positions with different byte values in two equal-length byte strings. */
#include <stddef.h>
#include <stdint.h>

#define MAX_BYTE_LENGTH 1024

int64_t hamming_distance_bytes(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > 2050) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_BYTE_LENGTH ||
        length != 1 + 2 * (size_t)count_value) return -1;

    const size_t count = (size_t)count_value;
    int64_t distance = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t left = values[1 + index];
        const int64_t right = values[1 + count + index];
        if (left < 0 || left > 255 || right < 0 || right > 255) return -1;
        if (left != right) ++distance;
    }
    return distance;
}
