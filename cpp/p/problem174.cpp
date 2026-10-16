/* Count tile counts represented by at most n_limit square laminae. */
#include <cstdint>
#include <vector>

namespace {
constexpr std::int64_t max_tiles = 1'000'000;

std::int64_t ceil_sqrt(std::int64_t value) noexcept
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

extern "C" std::int64_t problem174(std::int64_t t_limit, std::int64_t n_limit) noexcept
{
    if (t_limit > max_tiles) return -1;
    if (t_limit < 0) return 0;
    std::vector<std::uint8_t> count(static_cast<std::size_t>(t_limit) + 1, 0);
    for (std::int64_t outer_width = 3; outer_width < t_limit / 4 + 2; ++outer_width) {
        const auto outer_area = outer_width * outer_width;
        std::int64_t hole_lower = 1;
        if (outer_area > t_limit) {
            hole_lower = ceil_sqrt(outer_area - t_limit);
            if (hole_lower < 1) hole_lower = 1;
        }
        if ((outer_width - hole_lower) % 2 != 0) ++hole_lower;
        for (auto hole_width = hole_lower; hole_width < outer_width - 1; hole_width += 2) {
            const auto tiles = outer_area - hole_width * hole_width;
            ++count[static_cast<std::size_t>(tiles)];
        }
    }
    std::int64_t answer = 0;
    for (std::int64_t tiles = 1; tiles <= t_limit; ++tiles) {
        const auto representations = count[static_cast<std::size_t>(tiles)];
        answer += representations >= 1 && representations <= n_limit;
    }
    return answer;
}
