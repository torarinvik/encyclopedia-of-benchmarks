#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kCoordinateLimit = 10000;

struct Point {
    std::int64_t x;
    std::int64_t y;
};

std::int64_t orientation(Point a, Point b, Point c) noexcept {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

bool on_segment(Point a, Point b, Point p) noexcept {
    return orientation(a, b, p) == 0 &&
           std::min(a.x, b.x) <= p.x && p.x <= std::max(a.x, b.x) &&
           std::min(a.y, b.y) <= p.y && p.y <= std::max(a.y, b.y);
}

bool segments_intersect(Point a, Point b, Point c, Point d) noexcept {
    const auto ab_c = orientation(a, b, c);
    const auto ab_d = orientation(a, b, d);
    const auto cd_a = orientation(c, d, a);
    const auto cd_b = orientation(c, d, b);

    if (ab_c == 0 && on_segment(a, b, c)) return true;
    if (ab_d == 0 && on_segment(a, b, d)) return true;
    if (cd_a == 0 && on_segment(c, d, a)) return true;
    if (cd_b == 0 && on_segment(c, d, b)) return true;
    return (ab_c < 0 && ab_d > 0 || ab_c > 0 && ab_d < 0) &&
           (cd_a < 0 && cd_b > 0 || cd_a > 0 && cd_b < 0);
}
}

extern "C" std::int64_t line_segment_intersection(const std::int64_t* values,
                                                   std::size_t length,
                                                   std::uint8_t* output,
                                                   std::size_t output_capacity) noexcept {
    (void)output;
    (void)output_capacity;
    if (values == nullptr || length != 8) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < -kCoordinateLimit || values[index] > kCoordinateLimit) return -1;

    const Point a{values[0], values[1]};
    const Point b{values[2], values[3]};
    const Point c{values[4], values[5]};
    const Point d{values[6], values[7]};
    return segments_intersect(a, b, c, d) ? 1 : 0;
}
