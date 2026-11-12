#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32;
constexpr std::size_t max_input = 131;
constexpr std::int64_t max_coord = 1'000'000;
struct Point { std::int64_t x, y; };

std::int64_t cross(Point a, Point b) { return a.x * b.y - a.y * b.x; }
Point edge(const Point* p, std::size_t n, std::size_t i) {
    const Point next = p[(i + 1) % n];
    return {next.x - p[i].x, next.y - p[i].y};
}
int half(Point v) { return (v.y > 0 || (v.y == 0 && v.x >= 0)) ? 0 : 1; }
int angle_compare(Point a, Point b) {
    const int ha = half(a), hb = half(b);
    if (ha != hb) return ha < hb ? -1 : 1;
    const auto turn = cross(a, b);
    return turn > 0 ? -1 : (turn < 0 ? 1 : 0);
}
bool valid_polygon(const Point* p, std::size_t n) {
    std::size_t wraps = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const Point a = edge(p, n, i), b = edge(p, n, (i + 1) % n);
        if ((a.x == 0 && a.y == 0) || cross(a, b) <= 0) return false;
        if (angle_compare(b, a) < 0) ++wraps;
    }
    return wraps == 1;
}
void rotate_lowest(Point* p, std::size_t n) {
    std::size_t first = 0;
    for (std::size_t i = 1; i < n; ++i)
        if (p[i].y < p[first].y || (p[i].y == p[first].y && p[i].x < p[first].x)) first = i;
    Point tmp[max_vertices];
    for (std::size_t i = 0; i < n; ++i) tmp[i] = p[(first + i) % n];
    for (std::size_t i = 0; i < n; ++i) p[i] = tmp[i];
}
void put_i64(std::uint8_t* out, std::size_t& at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at++] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t minkowski_sum_convex_polygons(const std::int64_t* v,
        std::size_t n, std::uint8_t* out, std::size_t cap) noexcept {
    if (!v || n < 14 || n > max_input || v[0] < 3 || v[0] > 32 || v[1] < 3 || v[1] > 32) return -1;
    const auto pn = static_cast<std::size_t>(v[0]), qn = static_cast<std::size_t>(v[1]);
    if (n != 2 + 2 * pn + 2 * qn) return -1;
    Point p[max_vertices], q[max_vertices], sum[2 * max_vertices];
    std::size_t at = 2;
    for (std::size_t i = 0; i < pn; ++i) {
        p[i] = {v[at], v[at + 1]}; at += 2;
        if (p[i].x < -max_coord || p[i].x > max_coord || p[i].y < -max_coord || p[i].y > max_coord) return -1;
    }
    for (std::size_t i = 0; i < qn; ++i) {
        q[i] = {v[at], v[at + 1]}; at += 2;
        if (q[i].x < -max_coord || q[i].x > max_coord || q[i].y < -max_coord || q[i].y > max_coord) return -1;
    }
    if (!valid_polygon(p, pn) || !valid_polygon(q, qn)) return -1;
    rotate_lowest(p, pn); rotate_lowest(q, qn);
    std::size_t i = 0, j = 0, count = 0;
    while (i < pn || j < qn) {
        sum[count++] = {p[i % pn].x + q[j % qn].x, p[i % pn].y + q[j % qn].y};
        if (i == pn) { ++j; continue; }
        if (j == qn) { ++i; continue; }
        const int order = angle_compare(edge(p, pn, i), edge(q, qn, j));
        if (order <= 0) ++i;
        if (order >= 0) ++j;
    }
    const std::size_t needed = (1 + 2 * count) * 8;
    if (needed > cap || !out) return -2;
    std::size_t offset = 0;
    put_i64(out, offset, static_cast<std::int64_t>(count));
    for (std::size_t k = 0; k < count; ++k) { put_i64(out, offset, sum[k].x); put_i64(out, offset, sum[k].y); }
    return static_cast<std::int64_t>(needed);
}
