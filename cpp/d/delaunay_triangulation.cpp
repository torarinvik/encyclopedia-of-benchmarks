#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_points = 8;
constexpr int max_vertices = max_points + 3;
constexpr int max_work_triangles = 2 * max_points + 1;
constexpr int max_work_edges = 3 * max_work_triangles;
constexpr int max_triangles = 2 * max_points - 5;
constexpr std::size_t max_output_bytes = 8 * (1 + 3 * max_triangles);
constexpr double circumcircle_epsilon = 1e-4;

struct Point { double x, y; };
struct Edge { int a, b; };
struct Triangle { int a, b, c; double cx, cy, radius_squared; };

std::int64_t orient(std::int64_t ax, std::int64_t ay, std::int64_t bx, std::int64_t by,
                    std::int64_t cx, std::int64_t cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}
std::int64_t incircle(std::int64_t ax, std::int64_t ay, std::int64_t bx, std::int64_t by,
                      std::int64_t cx, std::int64_t cy, std::int64_t dx, std::int64_t dy) {
    const auto x1 = ax - dx, y1 = ay - dy, x2 = bx - dx, y2 = by - dy, x3 = cx - dx, y3 = cy - dy;
    const auto q1 = x1 * x1 + y1 * y1, q2 = x2 * x2 + y2 * y2, q3 = x3 * x3 + y3 * y3;
    return q1 * (x2 * y3 - y2 * x3) - q2 * (x1 * y3 - y1 * x3) + q3 * (x1 * y2 - y1 * x2);
}
bool same_edge(Edge x, Edge y) { return (x.a == y.a && x.b == y.b) || (x.a == y.b && x.b == y.a); }

Triangle make_triangle(const Point* points, int a, int b, int c) {
    const Point p0 = points[a], p1 = points[b], p2 = points[c];
    const double ax = p1.x - p0.x, ay = p1.y - p0.y, bx = p2.x - p0.x, by = p2.y - p0.y;
    const double m = p1.x * p1.x - p0.x * p0.x + p1.y * p1.y - p0.y * p0.y;
    const double u = p2.x * p2.x - p0.x * p0.x + p2.y * p2.y - p0.y * p0.y;
    const double scale = 1.0 / (2.0 * (ax * by - ay * bx));
    const double cx = ((p2.y - p0.y) * m + (p0.y - p1.y) * u) * scale;
    const double cy = ((p0.x - p2.x) * m + (p1.x - p0.x) * u) * scale;
    const double dx = p0.x - cx, dy = p0.y - cy;
    return {a, b, c, cx, cy, dx * dx + dy * dy};
}
void sort_indices(int& a, int& b, int& c) {
    if (a > b) { const int t = a; a = b; b = t; }
    if (b > c) { const int t = b; b = c; c = t; }
    if (a > b) { const int t = a; a = b; b = t; }
}
bool triangle_less(const Triangle& a, const Triangle& b) {
    if (a.a != b.a) return a.a < b.a;
    if (a.b != b.b) return a.b < b.b;
    return a.c < b.c;
}
void put_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { output[offset + i] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
} // namespace

extern "C" std::int64_t delaunay_triangulation(const std::int64_t* values, std::size_t length,
                                                std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 7 || length > 17 || values[0] < 3 || values[0] > max_points ||
        length != 1 + 2 * static_cast<std::size_t>(values[0])) return -1;
    const int n = static_cast<int>(values[0]);
    std::int64_t ix[max_points]{}, iy[max_points]{};
    Point points[max_vertices]{};
    std::int64_t min_x = 0, max_x = 0, min_y = 0, max_y = 0;
    for (int i = 0; i < n; ++i) {
        const auto x = values[1 + 2 * i], y = values[2 + 2 * i];
        if (x < -10 || x > 10 || y < -10 || y > 10) return -1;
        for (int j = 0; j < i; ++j) if (ix[j] == x && iy[j] == y) return -1;
        ix[i] = x; iy[i] = y; points[i] = {static_cast<double>(x), static_cast<double>(y)};
        if (i == 0) { min_x = max_x = x; min_y = max_y = y; }
        else { if (x < min_x) min_x = x; if (x > max_x) max_x = x; if (y < min_y) min_y = y; if (y > max_y) max_y = y; }
    }
    for (int a = 0; a < n; ++a) for (int b = a + 1; b < n; ++b) for (int c = b + 1; c < n; ++c)
        if (orient(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c]) == 0) return -1;
    for (int a = 0; a < n; ++a) for (int b = a + 1; b < n; ++b) for (int c = b + 1; c < n; ++c) for (int d = c + 1; d < n; ++d)
        if (incircle(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c], ix[d], iy[d]) == 0) return -1;

    const auto dmax = (max_x - min_x) > (max_y - min_y) ? (max_x - min_x) : (max_y - min_y);
    const double midx = (static_cast<double>(min_x) + static_cast<double>(max_x)) / 2.0;
    const double midy = (static_cast<double>(min_y) + static_cast<double>(max_y)) / 2.0;
    const int s0 = n, s1 = n + 1, s2 = n + 2;
    points[s0] = {midx - 20.0 * static_cast<double>(dmax), midy - static_cast<double>(dmax)};
    points[s1] = {midx, midy + 20.0 * static_cast<double>(dmax)};
    points[s2] = {midx + 20.0 * static_cast<double>(dmax), midy - static_cast<double>(dmax)};
    for (int a = 0; a < n + 3; ++a) for (int b = a + 1; b < n + 3; ++b) for (int c = b + 1; c < n + 3; ++c)
        if ((points[b].x - points[a].x) * (points[c].y - points[a].y) -
            (points[b].y - points[a].y) * (points[c].x - points[a].x) == 0.0) return -1;

    Triangle current[max_work_triangles]{}, next[max_work_triangles]{};
    Edge edges[max_work_edges]{};
    int current_count = 1;
    current[0] = make_triangle(points, s0, s1, s2);
    for (int p = 0; p < n; ++p) {
        int edge_count = 0, next_count = 0;
        for (int i = 0; i < current_count; ++i) {
            const Triangle t = current[i];
            const double dx = t.cx - points[p].x, dy = t.cy - points[p].y;
            if (dx * dx + dy * dy - t.radius_squared <= circumcircle_epsilon) {
                edges[edge_count++] = {t.a, t.b}; edges[edge_count++] = {t.b, t.c}; edges[edge_count++] = {t.a, t.c};
            } else { if (next_count >= max_work_triangles) return -1; next[next_count++] = t; }
        }
        bool remove[max_work_edges]{};
        for (int i = 0; i < edge_count; ++i) for (int j = 0; j < edge_count; ++j)
            if (i != j && same_edge(edges[i], edges[j])) remove[i] = remove[j] = true;
        for (int i = 0; i < edge_count; ++i) if (!remove[i]) {
            if (next_count >= max_work_triangles) return -1;
            next[next_count++] = make_triangle(points, edges[i].a, edges[i].b, p);
        }
        for (int i = 0; i < next_count; ++i) current[i] = next[i];
        current_count = next_count;
    }
    Triangle result[max_triangles]{};
    int result_count = 0;
    for (int i = 0; i < current_count; ++i) {
        Triangle t = current[i];
        if (t.a >= n || t.b >= n || t.c >= n) continue;
        if (result_count >= max_triangles) return -1;
        sort_indices(t.a, t.b, t.c);
        int j = result_count++;
        while (j > 0 && triangle_less(t, result[j - 1])) { result[j] = result[j - 1]; --j; }
        result[j] = t;
    }
    if (result_count == 0) return -1;
    std::uint8_t staged[max_output_bytes]{};
    put_i64(staged, 0, result_count);
    for (int i = 0; i < result_count; ++i) {
        put_i64(staged, 8 + 24 * static_cast<std::size_t>(i), result[i].a);
        put_i64(staged, 16 + 24 * static_cast<std::size_t>(i), result[i].b);
        put_i64(staged, 24 + 24 * static_cast<std::size_t>(i), result[i].c);
    }
    const auto required = 8 + 24 * static_cast<std::size_t>(result_count);
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}
