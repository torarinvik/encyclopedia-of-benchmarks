/* Sum water trapped between bounded, nonnegative elevation bars. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 4096;
constexpr int64_t MAX_HEIGHT = 1000000;
}

extern "C" int64_t trapped_rainwater(const int64_t *heights, std::size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && heights == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (heights[index] < 0 || heights[index] > MAX_HEIGHT) return -1;
    if (length < 3) return 0;

    int64_t left_max[MAX_LENGTH], right_max[MAX_LENGTH];
    left_max[0] = heights[0];
    for (std::size_t index = 1; index < length; ++index)
        left_max[index] = left_max[index - 1] > heights[index] ? left_max[index - 1] : heights[index];
    right_max[length - 1] = heights[length - 1];
    for (std::size_t index = length - 1; index > 0; --index) {
        const std::size_t previous = index - 1;
        right_max[previous] = right_max[index] > heights[previous] ? right_max[index] : heights[previous];
    }

    int64_t water = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const int64_t boundary = left_max[index] < right_max[index] ? left_max[index] : right_max[index];
        water += boundary - heights[index];
    }
    return water;
}
