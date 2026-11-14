// Chan hull draft. Not compiled or run; tangent-search invariants need review.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
struct Point { std::int64_t x, y; };
std::int64_t cross(Point a, Point b, Point c) {
    return (b.x-a.x)*(c.y-a.y) - (b.y-a.y)*(c.x-a.x);
}

std::vector<std::size_t> group_hull(const std::vector<Point>& points, std::size_t begin, std::size_t end) {
    std::vector<std::size_t> order, lower, upper;
    for (auto i = begin; i < end; ++i) order.push_back(i);
    std::sort(order.begin(), order.end(), [&](auto a, auto b) {
        return points[a].x < points[b].x || (points[a].x == points[b].x && points[a].y < points[b].y);
    });
    if (order.size() == 1) return order;
    for (auto id : order) {
        while (lower.size() >= 2 && cross(points[lower[lower.size()-2]], points[lower.back()], points[id]) <= 0) lower.pop_back();
        lower.push_back(id);
    }
    for (auto it = order.rbegin(); it != order.rend(); ++it) {
        while (upper.size() >= 2 && cross(points[upper[upper.size()-2]], points[upper.back()], points[*it]) <= 0) upper.pop_back();
        upper.push_back(*it);
    }
    lower.pop_back(); upper.pop_back();
    lower.insert(lower.end(), upper.begin(), upper.end());
    return lower;
}

std::size_t external_tangent(const std::vector<Point>& points, const std::vector<std::size_t>& hull, std::size_t q) {
    const auto size = hull.size();
    auto turn = [&](std::size_t a, std::size_t b) { return cross(points[q], points[hull[a]], points[hull[b]]); };
    if (size == 1) return hull[0];
    if (size == 2) return hull[turn(0, 1) > 0 ? 0 : 1];
    const bool initial_up = turn(0, 1) > 0;
    std::size_t lo = 0, hi = size;
    while (lo < hi) {
        const auto mid = lo + (hi-lo)/2;
        const bool less_prev = turn(mid, (mid+size-1)%size) > 0;
        const bool less_next = turn(mid, (mid+1)%size) > 0;
        if (less_prev && less_next) return hull[mid];
        const bool before_anchor = mid != 0 && turn(mid, 0) > 0;
        const bool after_anchor = mid != 0 && turn(0, mid) > 0;
        const bool left = initial_up ? (less_next && before_anchor) : (less_next || after_anchor);
        if (left) hi = mid; else lo = mid+1;
    }
    return points.size();
}
}

extern "C" std::int64_t chan_output_sensitive_hull(const std::int64_t* input, std::size_t length,
                                                    std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 7 || length > 66 || input[0] < 3 || input[0] > 32) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2*n) return -1;
    std::vector<Point> points;
    for (std::size_t i = 0; i < n; ++i) {
        Point p{input[1+2*i], input[2+2*i]};
        if (p.x < -1000 || p.x > 1000 || p.y < -1000 || p.y > 1000) return -1;
        for (const auto& q : points) if (p.x == q.x && p.y == q.y) return -1;
        points.push_back(p);
    }
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = i+1; j < n; ++j)
            for (std::size_t k = j+1; k < n; ++k)
                if (cross(points[i], points[j], points[k]) == 0) return -1;
    std::size_t start = 0;
    for (std::size_t i = 1; i < n; ++i)
        if (points[i].x < points[start].x || (points[i].x == points[start].x && points[i].y < points[start].y)) start = i;
    std::size_t guess = std::min<std::size_t>(4, n);
    for (;;) {
        std::vector<std::vector<std::size_t>> groups;
        std::vector<std::size_t> group_of(n), position(n, n);
        for (std::size_t begin = 0; begin < n; begin += guess) {
            const auto end = std::min(n, begin+guess);
            for (auto i = begin; i < end; ++i) group_of[i] = groups.size();
            groups.push_back(group_hull(points, begin, end));
            for (std::size_t i = 0; i < groups.back().size(); ++i) position[groups.back()[i]] = i;
        }
        std::vector<std::size_t> hull{start};
        for (std::size_t step = 0; step < guess; ++step) {
            auto current = hull.back(), candidate = n;
            for (std::size_t g = 0; g < groups.size(); ++g) {
                const auto& part = groups[g];
                std::size_t local = n;
                if (g == group_of[current]) {
                    if (position[current] == n) return -1;
                    if (part.size() > 1) local = part[(position[current]+1)%part.size()];
                } else {
                    local = external_tangent(points, part, current);
                    if (local == n) return -1;
                }
                if (local != n && (candidate == n || cross(points[current], points[candidate], points[local]) < 0)) candidate = local;
            }
            if (candidate == n) return -1;
            if (candidate == start) {
                const auto bytes = 16*hull.size();
                if (!output || capacity < bytes) return -2;
                for (std::size_t i = 0; i < hull.size(); ++i) {
                    const std::uint64_t fields[2] = {static_cast<std::uint64_t>(points[hull[i]].x), static_cast<std::uint64_t>(points[hull[i]].y)};
                    for (std::size_t a = 0; a < 2; ++a)
                        for (std::size_t b = 0; b < 8; ++b) output[16*i+8*a+b] = static_cast<std::uint8_t>(fields[a] >> (8*b));
                }
                return static_cast<std::int64_t>(bytes);
            }
            if (hull.size() == n) return -1;
            hull.push_back(candidate);
        }
        if (guess == n) return -1;
        guess = std::min(n, guess*guess);
    }
}
