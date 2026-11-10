#include <algorithm>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t trapped_rainwater_two_pointer(const std::int64_t *heights, std::size_t length)
{
    if (length > 4096 || (length != 0 && heights == nullptr)) return -1;
    if (length == 0) return 0;

    std::size_t left = 0, right = length - 1;
    std::uint64_t left_height = static_cast<std::uint64_t>(heights[left]);
    std::uint64_t right_height = static_cast<std::uint64_t>(heights[right]);
    if (left_height > 1000000 || right_height > 1000000) return -1;

    std::uint32_t left_max = 0, right_max = 0, trapped = 0;
    while (left < right) {
        if (left_height < right_height) {
            const std::uint32_t height = static_cast<std::uint32_t>(left_height);
            left_max = std::max(height, left_max);
            trapped += left_max - height;
            left_height = static_cast<std::uint64_t>(heights[++left]);
            if (left_height > 1000000) return -1;
        } else {
            const std::uint32_t height = static_cast<std::uint32_t>(right_height);
            right_max = std::max(height, right_max);
            trapped += right_max - height;
            right_height = static_cast<std::uint64_t>(heights[--right]);
            if (right_height > 1000000) return -1;
        }
    }
    return trapped;
}
