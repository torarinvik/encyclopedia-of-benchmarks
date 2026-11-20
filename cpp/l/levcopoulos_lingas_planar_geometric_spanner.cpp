#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <set>
#include <tuple>
#include <utility>
#include <vector>

namespace {
constexpr std::size_t kMaxN = 8;
constexpr std::size_t kMaxEdges = 18;
constexpr std::size_t kMaxFaces = 16;
constexpr std::size_t kMaxInput = 55;
constexpr std::size_t kMaxOutputBytes = 312;
using Point = std::pair<std::int64_t, std::int64_t>;
using Edge = std::pair<int, int>;
using Dart = std::pair<int, int>;
using Face = std::array<int, 3>;

std::int64_t orient(const Point& a, const Point& b, const Point& c) {
    return (b.first - a.first) * (c.second - a.second)
         - (b.second - a.second) * (c.first - a.first);
}

std::int64_t incircle_det(const Point& a, const Point& b, const Point& c, const Point& p) {
    const auto ax = a.first - p.first, ay = a.second - p.second;
    const auto bx = b.first - p.first, by = b.second - p.second;
    const auto cx = c.first - p.first, cy = c.second - p.second;
    return (ax * ax + ay * ay) * (bx * cy - by * cx)
         - (bx * bx + by * by) * (ax * cy - ay * cx)
         + (cx * cx + cy * cy) * (ax * by - ay * bx);
}

std::int64_t squared_distance(const std::vector<Point>& points, int a, int b) {
    const auto dx = points[a].first - points[b].first;
    const auto dy = points[a].second - points[b].second;
    return dx * dx + dy * dy;
}

Face canonical_face(int a, int b, int c) {
    Face result{a, b, c};
    std::sort(result.begin(), result.end());
    return result;
}

bool angle_less(const std::vector<Point>& points, int origin, int a, int b) {
    const auto ax = points[a].first - points[origin].first;
    const auto ay = points[a].second - points[origin].second;
    const auto bx = points[b].first - points[origin].first;
    const auto by = points[b].second - points[origin].second;
    const int ah = (ay > 0 || (ay == 0 && ax >= 0)) ? 0 : 1;
    const int bh = (by > 0 || (by == 0 && bx >= 0)) ? 0 : 1;
    if (ah != bh) return ah < bh;
    const auto cross = ax * by - ay * bx;
    return cross != 0 ? cross > 0 : a < b;
}

struct State {
    std::vector<Point> points;
    std::vector<Edge> edges;
    std::set<Face> faces;
    std::vector<std::vector<int>> rotation;
    std::vector<std::vector<int>> tree_rotation;
    std::vector<Dart> contour;
    std::vector<Dart> stack;
    std::array<std::array<double, kMaxN>, kMaxN> weight{};
    std::array<bool, kMaxN> hull{};
    std::array<std::array<bool, kMaxN>, kMaxN> tree{};
    std::array<std::array<bool, kMaxN>, kMaxN> kept{};
};

bool parse(const std::int64_t* input, std::size_t length, State& s) {
    if (!input || length < 14 || length > kMaxInput) return false;
    const auto n64 = input[0];
    if (n64 < 3 || n64 > static_cast<std::int64_t>(kMaxN)) return false;
    const int n = static_cast<int>(n64);
    const std::size_t m_at = 1 + 2 * n;
    if (length <= m_at) return false;
    const auto m64 = input[m_at];
    if (m64 < 3 || m64 > static_cast<std::int64_t>(kMaxEdges)
        || length != m_at + 1 + 2 * static_cast<std::size_t>(m64)) return false;
    const int m = static_cast<int>(m64);
    s.points.reserve(n);
    for (int i = 0; i < n; ++i) {
        const Point point{input[1 + 2 * i], input[2 + 2 * i]};
        if (point.first < -10 || point.first > 10 || point.second < -10 || point.second > 10)
            return false;
        if (std::find(s.points.begin(), s.points.end(), point) != s.points.end()) return false;
        s.points.push_back(point);
    }
    for (int a = 0; a < n; ++a)
        for (int b = a + 1; b < n; ++b)
            for (int c = b + 1; c < n; ++c)
                if (orient(s.points[a], s.points[b], s.points[c]) == 0) return false;
    for (int a = 0; a < n; ++a)
        for (int b = a + 1; b < n; ++b)
            for (int c = b + 1; c < n; ++c)
                for (int d = c + 1; d < n; ++d)
                    if (incircle_det(s.points[a], s.points[b], s.points[c], s.points[d]) == 0)
                        return false;

    for (int i = 0; i < m; ++i) {
        const auto u64 = input[m_at + 1 + 2 * i];
        const auto v64 = input[m_at + 2 + 2 * i];
        if (u64 < 0 || v64 <= u64 || v64 >= n) return false;
        const Edge edge{static_cast<int>(u64), static_cast<int>(v64)};
        if (!s.edges.empty() && s.edges.back() >= edge) return false;
        s.edges.push_back(edge);
    }

    std::set<Edge> expected_edges;
    for (int a0 = 0; a0 < n; ++a0) {
        for (int b0 = a0 + 1; b0 < n; ++b0) {
            for (int c0 = b0 + 1; c0 < n; ++c0) {
                int a = a0, b = b0, c = c0;
                if (orient(s.points[a], s.points[b], s.points[c]) < 0) std::swap(b, c);
                bool empty = true;
                for (int p = 0; p < n; ++p) {
                    if (p != a && p != b && p != c
                        && incircle_det(s.points[a], s.points[b], s.points[c], s.points[p]) > 0) {
                        empty = false;
                        break;
                    }
                }
                if (empty) {
                    s.faces.insert(canonical_face(a, b, c));
                    expected_edges.insert(std::minmax(a, b));
                    expected_edges.insert(std::minmax(a, c));
                    expected_edges.insert(std::minmax(b, c));
                }
            }
        }
    }
    if (expected_edges != std::set<Edge>(s.edges.begin(), s.edges.end())) return false;

    for (int a = 0; a < n; ++a) {
        for (int b = a + 1; b < n; ++b) {
            bool positive = false, negative = false;
            for (int p = 0; p < n; ++p) {
                if (p == a || p == b) continue;
                const auto side = orient(s.points[a], s.points[b], s.points[p]);
                positive |= side > 0;
                negative |= side < 0;
            }
            if (!(positive && negative)) s.hull[a] = s.hull[b] = true;
        }
    }
    s.rotation.resize(n);
    s.tree_rotation.resize(n);
    for (const auto [u, v] : s.edges) {
        s.rotation[u].push_back(v);
        s.rotation[v].push_back(u);
    }
    for (int v = 0; v < n; ++v)
        std::sort(s.rotation[v].begin(), s.rotation[v].end(),
                  [&](int a, int b) { return angle_less(s.points, v, a, b); });
    return true;
}

int clockwise_next(const State& s, int u, int v) {
    const auto& around = s.rotation[v];
    const auto it = std::find(around.begin(), around.end(), u);
    if (it == around.end()) return -1;
    const auto at = static_cast<std::size_t>(it - around.begin());
    return around[(at + around.size() - 1) % around.size()];
}

int tree_clockwise_next(const State& s, int u, int v) {
    const auto& around = s.tree_rotation[v];
    const auto it = std::find(around.begin(), around.end(), u);
    if (it == around.end()) return -1;
    const auto at = static_cast<std::size_t>(it - around.begin());
    return around[(at + around.size() - 1) % around.size()];
}

void canonicalize(std::vector<Dart>& boundary) {
    const auto first = std::min_element(boundary.begin(), boundary.end());
    std::rotate(boundary.begin(), first, boundary.end());
}

bool contains_dart(const std::vector<Dart>& boundary, Dart dart) {
    return std::find(boundary.begin(), boundary.end(), dart) != boundary.end();
}

bool eligible(const State& s, Dart dart) {
    const auto it = std::find(s.contour.begin(), s.contour.end(), dart);
    if (it == s.contour.end() || s.hull[dart.second] || s.contour.size() < 3)
        return false;
    const auto at = static_cast<std::size_t>(it - s.contour.begin());
    const Dart following = s.contour[(at + 1) % s.contour.size()];
    const int next = clockwise_next(s, dart.first, dart.second);
    return following.first == dart.second && following.second == next
        && s.faces.find(canonical_face(dart.first, dart.second, next)) != s.faces.end();
}

bool build_tree(State& s) {
    std::vector<Edge> ordered = s.edges;
    std::sort(ordered.begin(), ordered.end(), [&](const Edge& a, const Edge& b) {
        return std::tuple{squared_distance(s.points, a.first, a.second), a.first, a.second}
             < std::tuple{squared_distance(s.points, b.first, b.second), b.first, b.second};
    });
    std::array<int, kMaxN> parent{}, size{};
    for (std::size_t i = 0; i < s.points.size(); ++i) { parent[i] = static_cast<int>(i); size[i] = 1; }
    auto find_root = [&](int vertex) {
        int root = vertex;
        while (parent[root] != root) root = parent[root];
        while (parent[vertex] != vertex) { const int next = parent[vertex]; parent[vertex] = root; vertex = next; }
        return root;
    };
    std::vector<Edge> tree;
    for (const auto [u, v] : ordered) {
        int a = find_root(u), b = find_root(v);
        if (a == b) continue;
        if (size[a] < size[b]) std::swap(a, b);
        parent[b] = a;
        size[a] += size[b];
        tree.emplace_back(u, v);
        s.tree[u][v] = s.tree[v][u] = true;
        s.kept[u][v] = s.kept[v][u] = true;
        s.tree_rotation[u].push_back(v);
        s.tree_rotation[v].push_back(u);
    }
    const int n = static_cast<int>(s.points.size());
    if (tree.size() != static_cast<std::size_t>(n - 1)) return false;
    for (int v = 0; v < n; ++v)
        std::sort(s.tree_rotation[v].begin(), s.tree_rotation[v].end(),
                  [&](int a, int b) { return angle_less(s.points, v, a, b); });

    for (const auto [u, v] : s.edges) {
        const double length = std::sqrt(static_cast<double>(squared_distance(s.points, u, v)));
        s.weight[u][v] = s.weight[v][u] = length;
    }
    Dart seed{n, n};
    for (const auto [u, v] : tree) {
        seed = std::min(seed, Dart{u, v});
        seed = std::min(seed, Dart{v, u});
    }
    s.contour.push_back(seed);
    const std::size_t expected = 2 * tree.size();
    while (true) {
        const Dart last = s.contour.back();
        const int next = tree_clockwise_next(s, last.first, last.second);
        if (next < 0) return false;
        const Dart dart{last.second, next};
        if (dart == seed) break;
        if (contains_dart(s.contour, dart) || s.contour.size() >= expected) return false;
        s.contour.push_back(dart);
    }
    return s.contour.size() == expected;
}

bool run(State& s, std::size_t& absorbed, std::size_t& shortcuts) {
    for (const Dart dart : s.contour)
        if (eligible(s, dart)) s.stack.push_back(dart);
    std::size_t steps = 0;
    while (!s.stack.empty() && steps < 2 * kMaxEdges) {
        const Dart dart = s.stack.back();
        s.stack.pop_back();
        if (!eligible(s, dart)) continue;
        const auto it = std::find(s.contour.begin(), s.contour.end(), dart);
        const std::size_t at = static_cast<std::size_t>(it - s.contour.begin());
        const std::size_t next_at = (at + 1) % s.contour.size();
        const int v = dart.first, w = dart.second, u = s.contour[next_at].second;
        const double path = s.weight[v][w] + s.weight[w][u];
        const double direct = std::sqrt(static_cast<double>(squared_distance(s.points, v, u)));
        if (path > 2.0 * direct) s.kept[v][u] = s.kept[u][v] = true;
        else s.weight[v][u] = path;

        const Dart chord{v, u};
        if (next_at == 0) {
            s.contour.erase(s.contour.begin() + static_cast<std::ptrdiff_t>(at));
            s.contour.erase(s.contour.begin());
            s.contour.push_back(chord);
        } else {
            s.contour[at] = chord;
            s.contour.erase(s.contour.begin() + static_cast<std::ptrdiff_t>(next_at));
        }
        canonicalize(s.contour);
        ++absorbed;
        ++steps;
        const auto chord_it = std::find(s.contour.begin(), s.contour.end(), chord);
        if (chord_it == s.contour.end()) return false;
        const auto pos = static_cast<std::size_t>(chord_it - s.contour.begin());
        const Dart left = s.contour[(pos + s.contour.size() - 1) % s.contour.size()];
        if (eligible(s, chord)) s.stack.push_back(chord);
        if (eligible(s, left)) s.stack.push_back(left);
    }
    if (steps >= 2 * kMaxEdges && !s.stack.empty()) return false;
    for (int u = 0; u < static_cast<int>(s.points.size()); ++u)
        for (int v = u + 1; v < static_cast<int>(s.points.size()); ++v)
            if (s.kept[u][v] && !s.tree[u][v]) ++shortcuts;
    return true;
}

void write_i64_le(std::uint8_t* output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = static_cast<std::uint8_t>((bits >> (8 * byte)) & 0xffU);
}
} // namespace

extern "C" std::int64_t levcopoulos_lingas_planar_geometric_spanner(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    State state;
    if (!parse(input, length, state) || !build_tree(state)) return -1;
    std::size_t absorbed = 0, shortcuts = 0;
    if (!run(state, absorbed, shortcuts)) return -1;
    std::vector<std::int64_t> words{static_cast<std::int64_t>(absorbed),
                                    static_cast<std::int64_t>(shortcuts), 0};
    for (int u = 0; u < static_cast<int>(state.points.size()); ++u) {
        for (int v = u + 1; v < static_cast<int>(state.points.size()); ++v) {
            if (state.kept[u][v]) {
                words.push_back(u);
                words.push_back(v);
                ++words[2];
            }
        }
    }
    const std::size_t bytes = words.size() * 8;
    if (!output || capacity < bytes) return -2;
    for (std::size_t i = 0; i < words.size(); ++i) write_i64_le(output, i, words[i]);
    return static_cast<std::int64_t>(bytes);
}
