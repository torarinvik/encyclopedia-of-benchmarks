#include <array>
#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr int kPoints = 8, kNodes = 15, kLeaf = 2;
struct Point { std::int64_t x, y; };
struct Node { int left, right, start, count; std::int64_t min_x, min_y, max_x, max_y; };
struct Tree { std::array<Point, kPoints> points{}; std::array<int, kPoints> order{};
              std::array<int, kPoints> scratch{}; std::array<Node, kNodes> nodes{}; int used = 0; };

int build(Tree& t, int start, int count) {
    const int id = t.used++;
    Node node{-1, -1, start, count, t.points[t.order[start]].x, t.points[t.order[start]].y,
              t.points[t.order[start]].x, t.points[t.order[start]].y};
    for (int i = 1; i < count; ++i) {
        const Point p = t.points[t.order[start + i]];
        if (p.x < node.min_x) node.min_x = p.x; if (p.x > node.max_x) node.max_x = p.x;
        if (p.y < node.min_y) node.min_y = p.y; if (p.y > node.max_y) node.max_y = p.y;
    }
    if (count <= kLeaf) { t.nodes[id] = node; return id; }
    const int axis = (node.max_x - node.min_x) > (node.max_y - node.min_y) ? 0 : 1;
    const std::int64_t midpoint_twice = axis == 0 ? node.min_x + node.max_x : node.min_y + node.max_y;
    int left_count = 0;
    for (int i = 0; i < count; ++i) {
        const Point p = t.points[t.order[start + i]];
        if (2 * (axis == 0 ? p.x : p.y) < midpoint_twice) ++left_count;
    }
    if (left_count == 0 || left_count == count) {
        left_count = (count + 1) / 2;
        for (int i = 0; i < count; ++i) t.scratch[i] = t.order[start + i];
    } else {
        int l = 0, r = left_count;
        for (int i = 0; i < count; ++i) {
            const int index = t.order[start + i]; const Point p = t.points[index];
            t.scratch[2 * (axis == 0 ? p.x : p.y) < midpoint_twice ? l++ : r++] = index;
        }
    }
    for (int i = 0; i < count; ++i) t.order[start + i] = t.scratch[i];
    const int left = build(t, start, left_count);
    const int right = build(t, start + left_count, count - left_count);
    node.left = left; node.right = right; node.count = 0; t.nodes[id] = node; return id;
}

std::int64_t box_distance(const Node& a, const Node& b) {
    std::int64_t dx = 0, dy = 0;
    if (a.max_x < b.min_x) dx = b.min_x - a.max_x; else if (b.max_x < a.min_x) dx = a.min_x - b.max_x;
    if (a.max_y < b.min_y) dy = b.min_y - a.max_y; else if (b.max_y < a.min_y) dy = a.min_y - b.max_y;
    return dx * dx + dy * dy;
}
void search(const Tree& a, int ai, const Tree& b, int bi, std::int64_t& best) {
    const Node& na = a.nodes[ai]; const Node& nb = b.nodes[bi];
    if (box_distance(na, nb) > best) return;
    const bool al = na.left < 0, bl = nb.left < 0;
    if (al && bl) {
        for (int i = 0; i < na.count; ++i) for (int j = 0; j < nb.count; ++j) {
            const Point p = a.points[a.order[na.start + i]], q = b.points[b.order[nb.start + j]];
            const std::int64_t dx = p.x - q.x, dy = p.y - q.y, d = dx * dx + dy * dy;
            if (d < best) best = d;
        }
    } else if (al) {
        const int l = nb.left, r = nb.right;
        if (box_distance(na, b.nodes[l]) < box_distance(na, b.nodes[r])) { search(a, ai, b, l, best); search(a, ai, b, r, best); }
        else { search(a, ai, b, r, best); search(a, ai, b, l, best); }
    } else if (bl) {
        const int l = na.left, r = na.right;
        if (box_distance(nb, a.nodes[l]) < box_distance(nb, a.nodes[r])) { search(a, l, b, bi, best); search(a, r, b, bi, best); }
        else { search(a, r, b, bi, best); search(a, l, b, bi, best); }
    } else {
        std::array<std::array<int, 2>, 4> pairs{{{{na.left, nb.left}}, {{na.left, nb.right}}, {{na.right, nb.left}}, {{na.right, nb.right}}}};
        std::array<std::int64_t, 4> d{};
        for (int i = 0; i < 4; ++i) d[i] = box_distance(a.nodes[pairs[i][0]], b.nodes[pairs[i][1]]);
        for (int i = 1; i < 4; ++i) {
            auto pair = pairs[i]; auto value = d[i]; int j = i;
            while (j > 0 && value < d[j - 1]) { pairs[j] = pairs[j - 1]; d[j] = d[j - 1]; --j; }
            pairs[j] = pair; d[j] = value;
        }
        for (const auto& pair : pairs) search(a, pair[0], b, pair[1], best);
    }
}
void write_i64_le(std::uint8_t *out, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (int i = 0; i < 8; ++i) out[i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}

// Clean-room bounded port; see package LICENSE.txt for ParGeo MIT attribution.
extern "C" std::int64_t pargeo_bichromatic_closest_pair(const std::int64_t *input, std::size_t length,
                                                          std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 10 || length > 34) return -1;
    if (input[0] < 2 || input[0] > kPoints || input[1] < 2 || input[1] > kPoints) return -1;
    const int na = static_cast<int>(input[0]), nb = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 2 * (na + nb))) return -1;
    for (std::size_t i = 2; i < length; ++i) if (input[i] < -1000000 || input[i] > 1000000) return -1;
    if (!output || capacity < 8) return -2;
    Tree a, b;
    for (int i = 0; i < na; ++i) { a.points[i] = {input[2 + 2 * i], input[3 + 2 * i]}; a.order[i] = i; }
    const int offset = 2 + 2 * na;
    for (int i = 0; i < nb; ++i) { b.points[i] = {input[offset + 2 * i], input[offset + 2 * i + 1]}; b.order[i] = i; }
    const int ra = build(a, 0, na), rb = build(b, 0, nb);
    std::int64_t best = INT64_MAX; search(a, ra, b, rb, best); write_i64_le(output, best); return 8;
}
