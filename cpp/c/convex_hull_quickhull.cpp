#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <vector>

namespace {
constexpr std::size_t kMaxPoints = 1024;
struct Point { std::int64_t x, y; std::size_t id; };

std::int64_t cross(const Point& a, const Point& b, const Point& c) noexcept {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

void quick_hull(const std::vector<Point>& points, std::size_t left, std::size_t right,
                std::vector<bool>& on_hull) {
    std::size_t farthest = points.size();
    std::int64_t greatest_area = 0;
    for (std::size_t index = 0; index < points.size(); ++index) {
        const auto area = cross(points[left], points[right], points[index]);
        if (area > greatest_area) { greatest_area = area; farthest = index; }
    }
    if (farthest == points.size()) return;
    on_hull[farthest] = true;
    quick_hull(points, left, farthest, on_hull);
    quick_hull(points, farthest, right, on_hull);
}
}

extern "C" std::int64_t convex_hull_quickhull(const std::int64_t* values, std::size_t length,
                                               std::uint8_t* output,
                                               std::size_t output_capacity) noexcept {
    if (length > 2 * kMaxPoints || length % 2 != 0 || (length != 0 && values == nullptr)) return -1;
    const std::size_t count = length / 2;
    std::vector<Point> points;
    points.reserve(count);
    for (std::size_t index = 0; index < count; ++index) {
        const auto x = values[2 * index], y = values[2 * index + 1];
        if (x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000) return -1;
        points.push_back({x, y, index});
    }
    if (points.empty()) return 0;
    std::sort(points.begin(), points.end(), [](const Point& a, const Point& b) {
        if (a.x != b.x) return a.x < b.x;
        if (a.y != b.y) return a.y < b.y;
        return a.id < b.id;
    });
    points.erase(std::unique(points.begin(), points.end(), [](const Point& a, const Point& b) {
        return a.x == b.x && a.y == b.y;
    }), points.end());

    std::vector<bool> on_hull(points.size(), false);
    if (points.size() == 1) on_hull[0] = true;
    else {
        on_hull.front() = on_hull.back() = true;
        quick_hull(points, 0, points.size() - 1, on_hull);
        quick_hull(points, points.size() - 1, 0, on_hull);
    }
    const auto hull_count = static_cast<std::size_t>(std::count(on_hull.begin(), on_hull.end(), true));
    if (output == nullptr || output_capacity < 4 * hull_count) return -2;
    std::size_t position = 0;
    for (std::size_t index = 0; index < points.size(); ++index) {
        if (!on_hull[index]) continue;
        const auto id = static_cast<std::uint32_t>(points[index].id);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[4 * position + byte] = static_cast<std::uint8_t>(id >> (8 * byte));
        ++position;
    }
    return static_cast<std::int64_t>(hull_count);
}
