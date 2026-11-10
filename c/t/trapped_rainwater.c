/* Sum water trapped between bounded, nonnegative elevation bars. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096
#define SHORT_LENGTH 16
#define MAX_HEIGHT UINT64_C(1000000)

static int64_t trapped_water_with_suffix(const int64_t *heights, size_t length,
                                         uint32_t *suffix)
{
    uint32_t boundary = 0;
    for (size_t index = length; index > 0;) {
        --index;
        const uint64_t raw = (uint64_t)heights[index];
        if (raw > MAX_HEIGHT) return -1;
        const uint32_t height = (uint32_t)raw;
        boundary = height > boundary ? height : boundary;
        suffix[index] = boundary;
    }

    uint32_t water = 0;
    boundary = 0;
    for (size_t index = 0; index < length; ++index) {
        const uint32_t height = (uint32_t)heights[index];
        boundary = height > boundary ? height : boundary;
        const uint32_t wall = suffix[index] < boundary ? suffix[index] : boundary;
        water += wall - height;
    }
    return water;
}

int64_t trapped_rainwater(const int64_t *heights, size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && heights == NULL)) return -1;
    if (length <= SHORT_LENGTH) {
        uint32_t suffix[SHORT_LENGTH];
        return trapped_water_with_suffix(heights, length, suffix);
    }
    uint32_t suffix[MAX_LENGTH];
    return trapped_water_with_suffix(heights, length, suffix);
}
