#include <cstddef>
#include <cstdint>

extern "C" std::int64_t trapped_rainwater_two_pointer(const std::int64_t* heights, std::size_t length) {
    if (length > 4096 || (length != 0 && heights == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (heights[i] < 0 || heights[i] > 1000000) return -1;
    if (length <= 2) return 0;
    std::size_t left = 0, right = length - 1;
    std::uint32_t left_max = 0, right_max = 0, trapped = 0;
    while (left < right) {
        if (heights[left] < heights[right]) {
            const auto h = static_cast<std::uint32_t>(heights[left]);
            if (h >= left_max) left_max = h; else trapped += left_max - h;
            ++left;
        } else {
            const auto h = static_cast<std::uint32_t>(heights[right]);
            if (h >= right_max) right_max = h; else trapped += right_max - h;
            --right;
        }
    }
    return static_cast<std::int64_t>(trapped);
}
