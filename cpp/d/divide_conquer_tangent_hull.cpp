// Unverified divide-and-conquer tangent-merge hull draft.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
struct Point { std::int64_t x, y; };
std::int64_t cross(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}

std::vector<std::size_t> chain(const std::vector<Point>& points, const std::vector<std::size_t>& order,
                               std::size_t lo, std::size_t hi, bool upper) {
    if (hi-lo == 1) return {order[lo]};
    const auto middle = lo+(hi-lo)/2;
    const auto left = chain(points, order, lo, middle, upper);
    const auto right = chain(points, order, middle, hi, upper);
    std::size_t i = left.size()-1, j = 0;
    bool changed = true;
    while (changed) {
        changed = false;
        while (i > 0) {
            const auto sign = cross(points[left[i]], points[right[j]], points[left[i-1]]);
            if (!(upper ? sign > 0 : sign < 0)) break;
            --i; changed = true;
        }
        while (j+1 < right.size()) {
            const auto sign = cross(points[left[i]], points[right[j]], points[right[j+1]]);
            if (!(upper ? sign > 0 : sign < 0)) break;
            ++j; changed = true;
        }
    }
    std::vector<std::size_t> merged;
    merged.reserve(i+1+right.size()-j);
    merged.insert(merged.end(), left.begin(), left.begin()+i+1);
    merged.insert(merged.end(), right.begin()+j, right.end());
    return merged;
}
}

extern "C" std::int64_t divide_conquer_tangent_hull(const std::int64_t* input, std::size_t length,
                                                    std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 7 || length > 66 || input[0] < 3 || input[0] > 32) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1+2*n) return -1;
    std::vector<Point> points;
    std::vector<std::size_t> order;
    points.reserve(n); order.reserve(n);
    for (std::size_t i = 0; i < n; ++i) {
        Point point{input[1+2*i], input[2+2*i]};
        if (point.x < -1000 || point.x > 1000 || point.y < -1000 || point.y > 1000) return -1;
        for (const auto& other : points) if (point.x == other.x) return -1;
        points.push_back(point); order.push_back(i);
    }
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = i+1; j < n; ++j)
            for (std::size_t k = j+1; k < n; ++k)
                if (cross(points[i], points[j], points[k]) == 0) return -1;
    std::sort(order.begin(), order.end(), [&](auto a, auto b) { return points[a].x < points[b].x; });
    const auto lower = chain(points, order, 0, n, false);
    const auto upper = chain(points, order, 0, n, true);
    std::vector<std::size_t> hull = lower;
    for (std::size_t i = upper.size()-1; i > 1;) hull.push_back(upper[--i]);
    const auto bytes = 16*hull.size();
    if (!output || capacity < bytes) return -2;
    for (std::size_t i = 0; i < hull.size(); ++i) {
        const std::uint64_t words[2] = {static_cast<std::uint64_t>(points[hull[i]].x),
                                        static_cast<std::uint64_t>(points[hull[i]].y)};
        for (std::size_t axis = 0; axis < 2; ++axis)
            for (std::size_t b = 0; b < 8; ++b)
                output[16*i+8*axis+b] = static_cast<std::uint8_t>(words[axis] >> (8*b));
    }
    return static_cast<std::int64_t>(bytes);
}
