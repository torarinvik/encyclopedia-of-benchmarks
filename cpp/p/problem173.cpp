/* Count square laminae using at most max_tiles tiles. */
#include <cstdint>

namespace {
constexpr std::int64_t max_tiles_limit = 1'000'000;

std::int64_t problem173_ceil_sqrt(std::int64_t value) noexcept
{
    if (value <= 0) return 0;
    std::int64_t root = value;
    std::int64_t next = (root + value / root) / 2;
    while (next < root) {
        root = next;
        next = (root + value / root) / 2;
    }
    return root * root == value ? root : root + 1;
}
}

extern "C" std::int64_t problem173(std::int64_t max_tiles) noexcept
{
    if (max_tiles < 0 || max_tiles > max_tiles_limit) return -1;
    std::int64_t answer = 0;
    for (std::int64_t outer_width = 3; outer_width < max_tiles / 4 + 2; ++outer_width) {
        std::int64_t hole_width = 1;
        const std::int64_t outer_area = outer_width * outer_width;
        if (outer_area > max_tiles) {
            hole_width = problem173_ceil_sqrt(outer_area - max_tiles);
            if (hole_width < 1) hole_width = 1;
        }
        if ((outer_width - hole_width) % 2 != 0) ++hole_width;
        answer += (outer_width - hole_width - 2) / 2 + 1;
    }
    return answer;
}
