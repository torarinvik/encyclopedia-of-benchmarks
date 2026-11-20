#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr int kMaxDepth = 2;
constexpr std::size_t kMaxInput = 25;
constexpr std::size_t kMaxOutputBytes = 1032;
using Point = std::array<int, 2>;
using Triangle = std::array<int, 3>;
using Edge = std::array<int, 2>;

struct State {
    std::array<Point, 5> points{};
    std::array<Triangle, 4> triangles{};
    std::vector<Edge> edges;
    std::vector<std::array<int, 2>> pairs;
    int vertex_count = 0;
    int triangle_count = 0;
    bool failed = false;
};

int orient(Point a, Point b, Point c) {
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
}

bool on_segment(Point a, Point b, Point p) {
    return std::min(a[0], b[0]) <= p[0] && p[0] <= std::max(a[0], b[0]) &&
           std::min(a[1], b[1]) <= p[1] && p[1] <= std::max(a[1], b[1]);
}

bool segments_intersect(Point a, Point b, Point c, Point d) {
    const int o1 = orient(a, b, c), o2 = orient(a, b, d);
    const int o3 = orient(c, d, a), o4 = orient(c, d, b);
    if (((o1 < 0 && o2 > 0) || (o1 > 0 && o2 < 0)) &&
        ((o3 < 0 && o4 > 0) || (o3 > 0 && o4 < 0))) return true;
    return (o1 == 0 && on_segment(a, b, c)) || (o2 == 0 && on_segment(a, b, d)) ||
           (o3 == 0 && on_segment(c, d, a)) || (o4 == 0 && on_segment(c, d, b));
}

bool edge_hits_box(const State& state, Edge edge, int xmin, int ymin, int xmax, int ymax) {
    const Point a = state.points[edge[0]], b = state.points[edge[1]];
    if ((xmin <= a[0] && a[0] <= xmax && ymin <= a[1] && a[1] <= ymax) ||
        (xmin <= b[0] && b[0] <= xmax && ymin <= b[1] && b[1] <= ymax)) return true;
    return segments_intersect(a, b, {xmin, ymin}, {xmax, ymin}) ||
           segments_intersect(a, b, {xmax, ymin}, {xmax, ymax}) ||
           segments_intersect(a, b, {xmax, ymax}, {xmin, ymax}) ||
           segments_intersect(a, b, {xmin, ymax}, {xmin, ymin});
}

bool stops(const State& state, int xmin, int ymin, int xmax, int ymax) {
    std::vector<Edge> touched;
    for (const Edge edge : state.edges)
        if (edge_hits_box(state, edge, xmin, ymin, xmax, ymax)) touched.push_back(edge);
    if (touched.empty()) return true;
    for (int vertex = 0; vertex < state.vertex_count; ++vertex) {
        if (std::all_of(touched.begin(), touched.end(), [vertex](Edge e) {
                return e[0] == vertex || e[1] == vertex;
            })) return true;
    }
    return false;
}

bool point_in_triangle(Point p, const State& state, Triangle t) {
    return orient(state.points[t[0]], state.points[t[1]], p) >= 0 &&
           orient(state.points[t[1]], state.points[t[2]], p) >= 0 &&
           orient(state.points[t[2]], state.points[t[0]], p) >= 0;
}

bool triangle_hits_box(const State& state, Triangle t,
                       int xmin, int ymin, int xmax, int ymax) {
    for (int v : t) {
        const Point p = state.points[v];
        if (xmin <= p[0] && p[0] <= xmax && ymin <= p[1] && p[1] <= ymax) return true;
    }
    const std::array<Point, 4> corners{Point{xmin, ymin}, Point{xmax, ymin},
                                      Point{xmax, ymax}, Point{xmin, ymax}};
    if (std::any_of(corners.begin(), corners.end(), [&](Point p) { return point_in_triangle(p, state, t); }))
        return true;
    for (int i = 0; i < 3; ++i)
        if (segments_intersect(state.points[t[i]], state.points[t[(i + 1) % 3]],
                               corners[0], corners[1]) ||
            segments_intersect(state.points[t[i]], state.points[t[(i + 1) % 3]],
                               corners[1], corners[2]) ||
            segments_intersect(state.points[t[i]], state.points[t[(i + 1) % 3]],
                               corners[2], corners[3]) ||
            segments_intersect(state.points[t[i]], state.points[t[(i + 1) % 3]],
                               corners[3], corners[0])) return true;
    return false;
}

void add_pair(State& state, int z, int triangle_id) {
    if (state.pairs.size() == 64) { state.failed = true; return; }
    state.pairs.push_back({z, triangle_id});
}

void visit(State& state, int depth, int ix, int iy, int path) {
    if (state.failed) return;
    const int size = 8 >> depth;
    const int xmin = ix * size, xmax = xmin + size;
    const int ymax = 8 - iy * size, ymin = ymax - size;
    if (!stops(state, xmin, ymin, xmax, ymax)) {
        if (depth == kMaxDepth) { state.failed = true; return; }
        for (int quadrant = 0; quadrant < 4; ++quadrant)
            visit(state, depth + 1, 2 * ix + (quadrant & 1),
                  2 * iy + (quadrant >> 1), 4 * path + quadrant);
        return;
    }
    const int z = path << (2 * (kMaxDepth - depth));
    for (int tid = 0; tid < state.triangle_count; ++tid)
        if (triangle_hits_box(state, state.triangles[tid], xmin, ymin, xmax, ymax))
            add_pair(state, z, tid);
}

bool add_edge(State& state, int a, int b) {
    if (a > b) std::swap(a, b);
    const Edge edge{a, b};
    if (std::find(state.edges.begin(), state.edges.end(), edge) != state.edges.end()) return true;
    if (state.edges.size() == 8) return false;
    state.edges.push_back(edge);
    return true;
}

bool parse(State& state, const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > kMaxInput) return false;
    if (!((input[0] == 4 && input[1] == 2) || (input[0] == 5 && input[1] == 4))) return false;
    state.vertex_count = static_cast<int>(input[0]);
    state.triangle_count = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 2 * state.vertex_count + 3 * state.triangle_count)) return false;
    const std::array<int, 8> corners{0, 0, 8, 0, 8, 8, 0, 8};
    for (int i = 0; i < 4; ++i) {
        if (input[2 + 2 * i] != corners[2 * i] || input[3 + 2 * i] != corners[2 * i + 1]) return false;
        state.points[i] = {corners[2 * i], corners[2 * i + 1]};
    }
    if (state.vertex_count == 5) {
        if (input[10] != 4 || input[11] != 4) return false;
        state.points[4] = {4, 4};
    }
    const std::size_t start = 2 + 2 * state.vertex_count;
    for (int i = 0; i < state.triangle_count; ++i)
        for (int j = 0; j < 3; ++j) {
            const std::int64_t id = input[start + 3 * i + j];
            if (id < 0 || id >= state.vertex_count) return false;
            state.triangles[i][j] = static_cast<int>(id);
        }
    if (state.vertex_count == 4) {
        const bool diag02 = state.triangles[0] == Triangle{0,1,2} && state.triangles[1] == Triangle{0,2,3};
        const bool diag13 = state.triangles[0] == Triangle{0,1,3} && state.triangles[1] == Triangle{1,2,3};
        if (!diag02 && !diag13) return false;
    } else if (state.triangles != std::array<Triangle, 4>{{{0,1,4},{1,2,4},{2,3,4},{3,0,4}}}) {
        return false;
    }
    for (int i = 0; i < state.triangle_count; ++i) {
        const Triangle triangle = state.triangles[i];
        if (!add_edge(state, triangle[0], triangle[1]) ||
            !add_edge(state, triangle[1], triangle[2]) ||
            !add_edge(state, triangle[2], triangle[0])) return false;
    }
    return true;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t star_quadtree_fat_triangulation(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    State state;
    if (!parse(state, input, length)) return -1;
    visit(state, 0, 0, 0, 0);
    if (state.failed) return -1;
    std::sort(state.pairs.begin(), state.pairs.end());
    const std::size_t bytes = (1 + 2 * state.pairs.size()) * 8;
    if (bytes > kMaxOutputBytes) return -1;
    if (output == nullptr || capacity < bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(state.pairs.size()));
    std::size_t cursor = 8;
    for (const auto& pair : state.pairs) {
        store_i64_le(output, cursor, pair[0]); cursor += 8;
        store_i64_le(output, cursor, pair[1]); cursor += 8;
    }
    return static_cast<std::int64_t>(bytes);
}
