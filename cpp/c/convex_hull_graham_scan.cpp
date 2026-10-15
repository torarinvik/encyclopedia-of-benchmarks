#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t kMaxPoints = 1024;
struct Point { std::int64_t x, y; std::size_t id; };

std::int64_t cross(const Point& a, const Point& b, const Point& c) noexcept {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
std::int64_t radius_squared(const Point& pivot, const Point& point) noexcept {
    const auto dx = point.x - pivot.x;
    const auto dy = point.y - pivot.y;
    return dx * dx + dy * dy;
}
}

extern "C" std::int64_t convex_hull_graham_scan(const std::int64_t* values, std::size_t length,
                                                  std::uint8_t* output,
                                                  std::size_t output_capacity) noexcept {
    if (length > 2 * kMaxPoints || length % 2 != 0 || (length != 0 && values == nullptr)) return -1;
    const std::size_t count = length / 2;
    std::vector<Point> input;
    input.reserve(count);
    for (std::size_t i = 0; i < count; ++i) {
        const auto x = values[2 * i], y = values[2 * i + 1];
        if (x < -1000000000 || x > 1000000000 || y < -1000000000 || y > 1000000000) return -1;
        input.push_back({x, y, i});
    }
    if (input.empty()) return 0;
    std::sort(input.begin(), input.end(), [](const Point& a, const Point& b) {
        if (a.x != b.x) return a.x < b.x;
        if (a.y != b.y) return a.y < b.y;
        return a.id < b.id;
    });
    std::vector<Point> points;
    points.reserve(input.size());
    for (const auto& point : input) {
        if (points.empty() || points.back().x != point.x || points.back().y != point.y)
            points.push_back(point);
    }
    const auto write = [&](const std::vector<std::size_t>& hull) -> std::int64_t {
        if (output == nullptr || output_capacity < 4 * hull.size()) return -2;
        for (std::size_t i = 0; i < hull.size(); ++i) {
            const auto id = static_cast<std::uint32_t>(points[hull[i]].id);
            for (std::size_t byte = 0; byte < 4; ++byte)
                output[4 * i + byte] = static_cast<std::uint8_t>(id >> (8 * byte));
        }
        return static_cast<std::int64_t>(hull.size());
    };
    if (points.size() == 1) return write({0});

    std::size_t pivot = 0;
    for (std::size_t i = 1; i < points.size(); ++i)
        if (points[i].y < points[pivot].y ||
            (points[i].y == points[pivot].y && points[i].x < points[pivot].x)) pivot = i;
    std::vector<std::size_t> order(points.size()), hull;
    for (std::size_t i = 0; i < order.size(); ++i) order[i] = i;
    std::sort(order.begin(), order.end(), [&](std::size_t a, std::size_t b) {
        const auto turn = cross(points[pivot], points[a], points[b]);
        if (turn != 0) return turn > 0;
        const auto da = radius_squared(points[pivot], points[a]);
        const auto db = radius_squared(points[pivot], points[b]);
        if (da != db) return da < db;
        return points[a].id < points[b].id;
    });
    bool all_collinear = true;
    for (std::size_t i = 2; i < order.size(); ++i)
        if (cross(points[pivot], points[order[1]], points[order[i]]) != 0) all_collinear = false;
    if (!all_collinear) {
        std::size_t ray_begin = order.size() - 1;
        while (ray_begin > 1 && cross(points[pivot], points[order[ray_begin - 1]],
                                      points[order.back()]) == 0) --ray_begin;
        std::reverse(order.begin() + static_cast<std::ptrdiff_t>(ray_begin), order.end());
    }
    for (const auto point : order) {
        while (hull.size() >= 2 && cross(points[hull[hull.size() - 2]],
                                        points[hull.back()], points[point]) < 0) hull.pop_back();
        hull.push_back(point);
    }
    return write(hull);
}
