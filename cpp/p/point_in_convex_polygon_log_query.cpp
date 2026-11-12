#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32, max_queries = 32, max_input = 131;
constexpr std::int64_t max_coord = 1'000'000;
struct Point { std::int64_t x, y; };
Point sub(Point a, Point b) { return {a.x - b.x, a.y - b.y}; }
std::int64_t cross(Point a, Point b) { return a.x * b.y - a.y * b.x; }
bool on_segment(Point a, Point b, Point p) {
    const auto e = sub(b, a), r = sub(p, a);
    return cross(e, r) == 0 && std::min(a.x, b.x) <= p.x && p.x <= std::max(a.x, b.x)
        && std::min(a.y, b.y) <= p.y && p.y <= std::max(a.y, b.y);
}
bool valid_polygon(const Point* p, std::size_t n) {
    for (std::size_t i = 0; i < n; ++i) {
        const auto next = (i + 1) % n;
        if (p[i].x == p[next].x && p[i].y == p[next].y) return false;
        const auto edge = sub(p[next], p[i]);
        for (std::size_t j = 0; j < n; ++j)
            if (j != i && j != next && cross(edge, sub(p[j], p[i])) <= 0) return false;
        for (std::size_t j = i + 1; j < n; ++j)
            if (p[i].x == p[j].x && p[i].y == p[j].y) return false;
    }
    return true;
}
std::int64_t contains_fan(const Point* fan, std::size_t m, Point query) {
    const Point origin{0, 0};
    const auto first = cross(fan[0], query), last = cross(fan[m - 1], query);
    if (first < 0 || last > 0) return 0;
    if (first == 0) return on_segment(origin, fan[0], query);
    if (last == 0) return on_segment(origin, fan[m - 1], query);
    std::size_t lo = 0, hi = m;
    while (hi - lo > 1) {
        const auto mid = (lo + hi) / 2;
        if (cross(fan[mid], query) >= 0) lo = mid; else hi = mid;
    }
    const auto side = cross(sub(fan[lo + 1], fan[lo]), sub(query, fan[lo]));
    if (side < 0) return 0;
    if (side == 0) return on_segment(fan[lo], fan[lo + 1], query);
    return 1;
}
void put_i64(std::uint8_t* out, std::size_t& offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[offset++] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t point_in_convex_polygon_log_query(const std::int64_t* v, std::size_t n,
        std::uint8_t* out, std::size_t cap) noexcept {
    if (!v || n < 2 || n > max_input || v[0] < 3 || v[0] > 32 || v[1] < 0 || v[1] > 32) return -1;
    const auto vertices = static_cast<std::size_t>(v[0]), queries = static_cast<std::size_t>(v[1]);
    if (n != 2 + 2 * vertices + 2 * queries) return -1;
    Point polygon[max_vertices], fan[max_vertices], query_points[max_queries];
    std::int64_t answers[max_queries];
    std::size_t at = 2;
    for (std::size_t i = 0; i < vertices; ++i) {
        polygon[i] = {v[at], v[at + 1]}; at += 2;
        if (polygon[i].x < -max_coord || polygon[i].x > max_coord || polygon[i].y < -max_coord || polygon[i].y > max_coord) return -1;
    }
    if (!valid_polygon(polygon, vertices)) return -1;
    for (std::size_t i = 0; i < queries; ++i) {
        query_points[i] = {v[at], v[at + 1]}; at += 2;
        if (query_points[i].x < -max_coord || query_points[i].x > max_coord || query_points[i].y < -max_coord || query_points[i].y > max_coord) return -1;
    }
    std::size_t pivot = 0;
    for (std::size_t i = 1; i < vertices; ++i)
        if (polygon[i].x < polygon[pivot].x || (polygon[i].x == polygon[pivot].x && polygon[i].y < polygon[pivot].y)) pivot = i;
    for (std::size_t i = 0; i + 1 < vertices; ++i) fan[i] = sub(polygon[(pivot + i + 1) % vertices], polygon[pivot]);
    for (std::size_t i = 0; i < queries; ++i) answers[i] = contains_fan(fan, vertices - 1, sub(query_points[i], polygon[pivot]));
    const auto needed = 8 * queries;
    if (needed > cap || (needed != 0 && !out)) return -2;
    std::size_t offset = 0;
    for (std::size_t i = 0; i < queries; ++i) put_i64(out, offset, answers[i]);
    return static_cast<std::int64_t>(needed);
}
