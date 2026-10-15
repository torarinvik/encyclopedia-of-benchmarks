// Area covered by the union of two axis-aligned rectangles.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t coordinate_limit = 1000000000; }

extern "C" std::int64_t rectangle_union_area(const std::int64_t *coordinates,
                                               std::size_t length) noexcept {
    if (coordinates == nullptr || length != 8) return -1;
    for (std::size_t index = 0; index < 8; ++index)
        if (coordinates[index] < -coordinate_limit || coordinates[index] > coordinate_limit)
            return -1;
    const auto ax1 = coordinates[0], ay1 = coordinates[1];
    const auto ax2 = coordinates[2], ay2 = coordinates[3];
    const auto bx1 = coordinates[4], by1 = coordinates[5];
    const auto bx2 = coordinates[6], by2 = coordinates[7];
    if (ax1 >= ax2 || ay1 >= ay2 || bx1 >= bx2 || by1 >= by2) return -1;
    const auto area_a = (ax2 - ax1) * (ay2 - ay1);
    const auto area_b = (bx2 - bx1) * (by2 - by1);
    const auto overlap_width = (ax2 < bx2 ? ax2 : bx2) - (ax1 > bx1 ? ax1 : bx1);
    const auto overlap_height = (ay2 < by2 ? ay2 : by2) - (ay1 > by1 ? ay1 : by1);
    const auto overlap = overlap_width > 0 && overlap_height > 0
        ? overlap_width * overlap_height : 0;
    return area_a + area_b - overlap;
}
