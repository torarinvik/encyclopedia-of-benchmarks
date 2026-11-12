#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 16, max_m = 42, max_input = 118, max_coord = 100;
using Point = std::array<std::int64_t, 2>;

std::int64_t orient(Point a, Point b, Point c) {
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
}
bool between(std::int64_t a, std::int64_t b, std::int64_t p) {
    return (a <= p && p <= b) || (b <= p && p <= a);
}
bool on_segment(Point a, Point b, Point p) {
    return between(a[0], b[0], p[0]) && between(a[1], b[1], p[1]);
}
bool intersects(Point a, Point b, Point c, Point d) {
    const auto ab_c = orient(a, b, c), ab_d = orient(a, b, d);
    const auto cd_a = orient(c, d, a), cd_b = orient(c, d, b);
    if (((ab_c > 0 && ab_d < 0) || (ab_c < 0 && ab_d > 0)) &&
        ((cd_a > 0 && cd_b < 0) || (cd_a < 0 && cd_b > 0))) return true;
    return (ab_c == 0 && on_segment(a, b, c)) || (ab_d == 0 && on_segment(a, b, d)) ||
           (cd_a == 0 && on_segment(c, d, a)) || (cd_b == 0 && on_segment(c, d, b));
}
int half(std::int64_t dx, std::int64_t dy) { return dy > 0 || (dy == 0 && dx >= 0) ? 0 : 1; }
bool angle_less(int a, int b, int origin, const std::array<Point, max_n>& points) {
    const auto ax = points[a][0] - points[origin][0], ay = points[a][1] - points[origin][1];
    const auto bx = points[b][0] - points[origin][0], by = points[b][1] - points[origin][1];
    if (half(ax, ay) != half(bx, by)) return half(ax, ay) < half(bx, by);
    return ax * by - ay * bx > 0;
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_m) return -1;
    const int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    const int edge_cap = n == 1 ? 0 : n == 2 ? 1 : 3 * n - 6;
    if (m > edge_cap || length != static_cast<std::size_t>(2 + 2 * n + 2 * m)) return -1;
    std::array<Point, max_n> points{};
    for (int v = 0; v < n; ++v) {
        points[v] = {input[2 + 2 * v], input[3 + 2 * v]};
        if (points[v][0] < -max_coord || points[v][0] > max_coord ||
            points[v][1] < -max_coord || points[v][1] > max_coord) return -1;
        for (int prior = 0; prior < v; ++prior) if (points[v] == points[prior]) return -1;
    }
    std::array<std::array<bool, max_n>, max_n> adjacent{};
    std::array<std::array<int, max_n>, max_n> neighbors{};
    std::array<int, max_n> degree{};
    std::array<int, max_m> edge_u{}, edge_v{};
    const std::size_t offset = static_cast<std::size_t>(2 + 2 * n);
    for (int e = 0; e < m; ++e) {
        const auto u0 = input[offset + static_cast<std::size_t>(2 * e)];
        const auto v0 = input[offset + static_cast<std::size_t>(2 * e + 1)];
        if (u0 < 0 || u0 >= n || v0 < 0 || v0 >= n || u0 == v0) return -1;
        const int u = static_cast<int>(u0), v = static_cast<int>(v0);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        neighbors[u][degree[u]++] = v; neighbors[v][degree[v]++] = u;
        edge_u[e] = u; edge_v[e] = v;
    }
    std::array<bool, max_n> reached{};
    std::array<int, max_n> queue{};
    int head = 0, tail = 0;
    reached[0] = true; queue[tail++] = 0;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v) if (adjacent[u][v] && !reached[v]) {
            reached[v] = true; queue[tail++] = v;
        }
    }
    for (int v = 0; v < n; ++v) if (!reached[v]) return -1;
    for (int i = 0; i < m; ++i) for (int j = i + 1; j < m; ++j) {
        const int u = edge_u[i], v = edge_v[i], a = edge_u[j], b = edge_v[j];
        int common = -1;
        if (u == a || u == b) common = u;
        if (v == a || v == b) common = common < 0 ? v : common;
        if (common >= 0) {
            const int p = u == common ? v : u, q = a == common ? b : a;
            const auto ax = points[p][0] - points[common][0], ay = points[p][1] - points[common][1];
            const auto bx = points[q][0] - points[common][0], by = points[q][1] - points[common][1];
            if (ax * by == ay * bx && ax * bx + ay * by > 0) return -1;
        } else if (intersects(points[u], points[v], points[a], points[b])) return -1;
    }
    if (n == 1) return 1;
    for (int u = 0; u < n; ++u) for (int i = 1; i < degree[u]; ++i) {
        const int key = neighbors[u][i];
        int j = i;
        while (j > 0 && angle_less(key, neighbors[u][j - 1], u, points)) {
            neighbors[u][j] = neighbors[u][j - 1]; --j;
        }
        neighbors[u][j] = key;
    }
    std::array<std::array<bool, max_n>, max_n> used{};
    int faces = 0;
    for (int e = 0; e < m; ++e) for (int direction = 0; direction < 2; ++direction) {
        int u = direction == 0 ? edge_u[e] : edge_v[e];
        int v = direction == 0 ? edge_v[e] : edge_u[e];
        if (used[u][v]) continue;
        ++faces;
        int steps = 0;
        while (!used[u][v]) {
            used[u][v] = true;
            int reverse = -1;
            for (int i = 0; i < degree[v]; ++i) if (neighbors[v][i] == u) reverse = i;
            if (reverse < 0 || degree[v] == 0) return -1;
            const int next = neighbors[v][(reverse + 1) % degree[v]];
            u = v; v = next;
            if (++steps > 2 * m) return -1;
        }
    }
    return faces;
}
}

extern "C" std::int64_t planar_face_count(const std::int64_t* input, std::size_t length) noexcept {
    return solve(input, length);
}
