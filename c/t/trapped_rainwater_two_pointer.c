#include <stddef.h>
#include <stdint.h>

int64_t trapped_rainwater_two_pointer(const int64_t *heights, size_t length)
{
    if (length > 4096 || (length != 0 && heights == NULL)) return -1;
    if (length == 0) return 0;

    size_t left = 0, right = length - 1;
    uint64_t left_height = (uint64_t)heights[left];
    uint64_t right_height = (uint64_t)heights[right];
    if (left_height > 1000000 || right_height > 1000000) return -1;

    uint32_t left_max = 0, right_max = 0, trapped = 0;
    while (left < right) {
        if (left_height < right_height) {
            const uint32_t height = (uint32_t)left_height;
            left_max = height > left_max ? height : left_max;
            trapped += left_max - height;
            left_height = (uint64_t)heights[++left];
            if (left_height > 1000000) return -1;
        } else {
            const uint32_t height = (uint32_t)right_height;
            right_max = height > right_max ? height : right_max;
            trapped += right_max - height;
            right_height = (uint64_t)heights[--right];
            if (right_height > 1000000) return -1;
        }
    }
    return trapped;
}
