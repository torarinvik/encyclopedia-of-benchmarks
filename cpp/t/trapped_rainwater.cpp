/* Sum water trapped between bounded, nonnegative elevation bars. */
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 4096;
constexpr std::size_t SHORT_LENGTH = 16;
constexpr std::uint64_t MAX_HEIGHT = 1000000;

std::int64_t trapped_water_with_suffix(const std::int64_t *heights, std::size_t length,
                                         std::uint32_t *suffix)
{
    std::uint32_t boundary = 0;
    for (std::size_t index = length; index > 0;) {
        --index;
        const std::uint64_t raw = static_cast<std::uint64_t>(heights[index]);
        if (raw > MAX_HEIGHT) return -1;
        const std::uint32_t height = static_cast<std::uint32_t>(raw);
        boundary = std::max(height, boundary);
        suffix[index] = boundary;
    }

    std::uint32_t water = 0;
    boundary = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::uint32_t height = static_cast<std::uint32_t>(heights[index]);
        boundary = std::max(height, boundary);
        const std::uint32_t wall = std::min(suffix[index], boundary);
        water += wall - height;
    }
    return water;
}

}

extern "C" std::int64_t trapped_rainwater(const std::int64_t *heights, std::size_t length)
{
    if (length > MAX_LENGTH || (length != 0 && heights == nullptr)) return -1;
    if (length <= SHORT_LENGTH) {
        std::uint32_t suffix[SHORT_LENGTH];
        return trapped_water_with_suffix(heights, length, suffix);
    }
    std::uint32_t suffix[MAX_LENGTH];
    return trapped_water_with_suffix(heights, length, suffix);
}
