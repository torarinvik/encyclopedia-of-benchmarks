/* Sum water trapped between bounded, nonnegative elevation bars. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096
#define MAX_HEIGHT INT64_C(1000000)

int64_t trapped_rainwater(const int64_t *heights, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && heights == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (heights[index] < 0 || heights[index] > MAX_HEIGHT) return -1;
    if (length < 3) return 0;

    int64_t left_max[MAX_LENGTH], right_max[MAX_LENGTH];
    left_max[0] = heights[0];
    for (size_t index = 1; index < length; ++index)
        left_max[index] = left_max[index - 1] > heights[index] ? left_max[index - 1] : heights[index];
    right_max[length - 1] = heights[length - 1];
    for (size_t index = length - 1; index > 0; --index) {
        const size_t previous = index - 1;
        right_max[previous] = right_max[index] > heights[previous] ? right_max[index] : heights[previous];
    }

    int64_t water = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t boundary = left_max[index] < right_max[index] ? left_max[index] : right_max[index];
        water += boundary - heights[index];
    }
    return water;
}
