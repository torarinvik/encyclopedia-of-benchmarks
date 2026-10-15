// Two-pointer maximum area between vertical lines.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t container_with_most_water(const std::int64_t *heights, std::size_t length)
{
    if (length > 4096) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (heights[index] < 0 || heights[index] > INT32_MAX) return -1;
    }
    if (length < 2) return 0;

    std::size_t left = 0;
    std::size_t right = length - 1;
    std::int64_t best = 0;
    while (left < right) {
        const std::int64_t left_height = heights[left];
        const std::int64_t right_height = heights[right];
        const std::int64_t height = left_height < right_height ? left_height : right_height;
        const std::int64_t area = height * static_cast<std::int64_t>(right - left);
        if (area > best) best = area;
        if (left_height <= right_height) ++left;
        else --right;
    }
    return best;
}
