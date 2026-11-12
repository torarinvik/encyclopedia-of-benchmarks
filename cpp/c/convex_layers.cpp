#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>
#include <vector>

namespace {
constexpr std::size_t max_points = 64;
constexpr std::int64_t coordinate_limit = 1'000'000;

struct Point { std::int64_t x; std::int64_t y; };

std::int64_t cross(const Point& a, const Point& b, const Point& c) noexcept {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

bool on_segment(const Point& point, const Point& a, const Point& b) noexcept {
    return cross(a, b, point) == 0 &&
        std::min(a.x, b.x) <= point.x && point.x <= std::max(a.x, b.x) &&
        std::min(a.y, b.y) <= point.y && point.y <= std::max(a.y, b.y);
}

std::vector<Point> monotone_hull(std::vector<Point> points) {
    std::sort(points.begin(), points.end(), [](const Point& a, const Point& b) {
        return a.x < b.x || (a.x == b.x && a.y < b.y);
    });
    if (points.size() <= 2) return points;
    std::vector<Point> hull;
    hull.reserve(2 * points.size());
    for (const Point& point : points) {
        while (hull.size() >= 2 && cross(hull[hull.size() - 2], hull.back(), point) <= 0)
            hull.pop_back();
        hull.push_back(point);
    }
    const std::size_t lower = hull.size();
    for (std::size_t i = points.size() - 1; i > 0; --i) {
        const Point& point = points[i - 1];
        while (hull.size() > lower && cross(hull[hull.size() - 2], hull.back(), point) <= 0)
            hull.pop_back();
        hull.push_back(point);
    }
    hull.pop_back();
    return hull;
}
}

extern "C" std::int64_t convex_layers(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > 1 + 2 * max_points) return -1;
    const std::int64_t count_value = input[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_points) ||
        length != 1 + 2 * static_cast<std::size_t>(count_value)) return -1;

    std::vector<Point> points;
    points.reserve(static_cast<std::size_t>(count_value));
    for (std::size_t i = 0; i < static_cast<std::size_t>(count_value); ++i) {
        const Point point{input[1 + 2 * i], input[2 + 2 * i]};
        if (point.x < -coordinate_limit || point.x > coordinate_limit ||
            point.y < -coordinate_limit || point.y > coordinate_limit) return -1;
        if (std::find_if(points.begin(), points.end(), [&](const Point& old) {
                return old.x == point.x && old.y == point.y;
            }) == points.end()) points.push_back(point);
    }

    std::int64_t layers = 0;
    while (!points.empty()) {
        const std::vector<Point> hull = monotone_hull(points);
        std::vector<Point> remaining;
        remaining.reserve(points.size());
        for (const Point& point : points) {
            bool boundary = hull.size() <= 2;
            for (std::size_t edge = 0; !boundary && edge < hull.size(); ++edge)
                boundary = on_segment(point, hull[edge], hull[(edge + 1) % hull.size()]);
            if (!boundary) remaining.push_back(point);
        }
        if (remaining.size() == points.size()) return -1;
        points = std::move(remaining);
        ++layers;
    }
    return layers;
}
