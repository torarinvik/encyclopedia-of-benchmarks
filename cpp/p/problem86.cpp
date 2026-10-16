#include <cstdint>

static bool is_square(std::int64_t value) noexcept
{
    auto root = value;
    auto next = (root + 1) / 2;
    while (next < root) { root = next; next = (root + value / root) / 2; }
    return root * root == value;
}

extern "C" std::int64_t problem86(std::int64_t limit) noexcept
{
    if (limit > 1000000) return -1;
    if (limit < 0) return 0;
    std::int64_t cuboid_count = 0, max_side = 0;
    while (cuboid_count <= limit) {
        ++max_side;
        for (std::int64_t sum_sides = 2; sum_sides <= 2 * max_side; ++sum_sides) {
            if (!is_square(sum_sides * sum_sides + max_side * max_side)) continue;
            const auto high = max_side < sum_sides / 2 ? max_side : sum_sides / 2;
            const auto low = sum_sides - max_side > 1 ? sum_sides - max_side : 1;
            cuboid_count += high - low + 1;
        }
    }
    return max_side;
}
