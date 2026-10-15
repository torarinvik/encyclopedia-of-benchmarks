#include <stddef.h>
#include <stdint.h>

int64_t trapped_rainwater_two_pointer(const int64_t *heights, size_t length) {
    if (length > 4096 || (length != 0 && heights == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) if (heights[i] < 0 || heights[i] > 1000000) return -1;
    if (length <= 2) return 0;
    size_t left = 0, right = length - 1;
    uint32_t left_max = 0, right_max = 0, trapped = 0;
    while (left < right) {
        if (heights[left] < heights[right]) {
            uint32_t h = (uint32_t)heights[left];
            if (h >= left_max) left_max = h; else trapped += left_max - h;
            ++left;
        } else {
            uint32_t h = (uint32_t)heights[right];
            if (h >= right_max) right_max = h; else trapped += right_max - h;
            --right;
        }
    }
    return (int64_t)trapped;
}
