#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::size_t max_points = 1024;
constexpr std::int64_t max_coordinate = 1'000'000'000;
constexpr double invalid_result = -1.0e300;

struct Point { std::int64_t x, y; };

bool before_xy(const Point &a, const Point &b) noexcept
{
    return a.x < b.x || (a.x == b.x && a.y < b.y);
}

std::int64_t cross(const Point &origin, const Point &a, const Point &b) noexcept
{
    return (a.x - origin.x) * (b.y - origin.y) - (a.y - origin.y) * (b.x - origin.x);
}

std::uint64_t distance_squared(const Point &a, const Point &b) noexcept
{
    const auto dx = a.x - b.x, dy = a.y - b.y;
    return static_cast<std::uint64_t>(dx * dx) + static_cast<std::uint64_t>(dy * dy);
}
}

extern "C" double rotating_calipers(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 5 || length > 2 * max_points + 1 || length % 2 == 0)
        return invalid_result;
    if (values[0] < 2 || values[0] > static_cast<std::int64_t>(max_points) ||
        length != 1 + 2 * static_cast<std::size_t>(values[0])) return invalid_result;

    std::vector<Point> points;
    points.reserve(static_cast<std::size_t>(values[0]));
    for (std::size_t index = 0; index < static_cast<std::size_t>(values[0]); ++index) {
        const auto x = values[1 + 2 * index], y = values[2 + 2 * index];
        if (x < -max_coordinate || x > max_coordinate || y < -max_coordinate || y > max_coordinate)
            return invalid_result;
        points.push_back({x, y});
    }
    std::sort(points.begin(), points.end(), before_xy);
    points.erase(std::unique(points.begin(), points.end(), [](const Point &a, const Point &b) {
        return a.x == b.x && a.y == b.y;
    }), points.end());
    if (points.size() == 1) return 0.0;

    std::vector<Point> lower, upper;
    lower.reserve(points.size());
    upper.reserve(points.size());
    for (const auto &point : points) {
        while (lower.size() >= 2 && cross(lower[lower.size() - 2], lower.back(), point) <= 0)
            lower.pop_back();
        lower.push_back(point);
    }
    for (auto iterator = points.rbegin(); iterator != points.rend(); ++iterator) {
        while (upper.size() >= 2 && cross(upper[upper.size() - 2], upper.back(), *iterator) <= 0)
            upper.pop_back();
        upper.push_back(*iterator);
    }
    std::vector<Point> hull;
    hull.reserve(lower.size() + upper.size() - 2);
    hull.insert(hull.end(), lower.begin(), lower.end() - 1);
    hull.insert(hull.end(), upper.begin(), upper.end() - 1);
    if (hull.size() == 2) return std::sqrt(static_cast<double>(distance_squared(hull[0], hull[1])));

    const std::size_t size = hull.size();
    std::size_t antipodal = 1, advances = 0;
    while (advances < size &&
           cross(hull[0], hull[1], hull[(antipodal + 1) % size]) >
           cross(hull[0], hull[1], hull[antipodal])) {
        antipodal = (antipodal + 1) % size;
        ++advances;
    }
    std::uint64_t maximum_squared = 0;
    for (std::size_t current = 0; current < size; ++current) {
        const std::size_t next = (current + 1) % size;
        advances = 0;
        while (advances < size &&
               cross(hull[current], hull[next], hull[(antipodal + 1) % size]) >
               cross(hull[current], hull[next], hull[antipodal])) {
            antipodal = (antipodal + 1) % size;
            ++advances;
        }
        const std::size_t after = (antipodal + 1) % size;
        maximum_squared = std::max(maximum_squared, distance_squared(hull[current], hull[antipodal]));
        maximum_squared = std::max(maximum_squared, distance_squared(hull[next], hull[antipodal]));
        maximum_squared = std::max(maximum_squared, distance_squared(hull[current], hull[after]));
        maximum_squared = std::max(maximum_squared, distance_squared(hull[next], hull[after]));
    }
    return std::sqrt(static_cast<double>(maximum_squared));
}
