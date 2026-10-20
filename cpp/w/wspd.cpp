#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_points = 8, max_nodes = 15, max_pairs = 28;
constexpr std::size_t max_output_bytes = 456;
struct Node { int left, right, count; std::uint64_t mask; double cx, cy, radius; };
struct Context {
    std::int64_t x[max_points]{}, y[max_points]{};
    Node nodes[max_nodes]{};
    std::uint64_t left_masks[max_pairs]{}, right_masks[max_pairs]{};
    int next_node = 0, pair_count = 0, point_count = 0, separation = 0;
    bool overflow = false;
};

bool point_less(const Context& c, int a, int b, int axis) {
    const auto a0 = axis == 0 ? c.x[a] : c.y[a], b0 = axis == 0 ? c.x[b] : c.y[b];
    const auto a1 = axis == 0 ? c.y[a] : c.x[a], b1 = axis == 0 ? c.y[b] : c.x[b];
    return a0 < b0 || (a0 == b0 && (a1 < b1 || (a1 == b1 && a < b)));
}
int build_node(Context& c, std::uint64_t mask) {
    const int id = c.next_node++;
    Node& node = c.nodes[id];
    node.left = node.right = -1; node.mask = mask; node.count = 0;
    int members[max_points]{}, used = 0;
    std::int64_t min_x = 0, max_x = 0, min_y = 0, max_y = 0;
    for (int i = 0; i < c.point_count; ++i) if (mask & (std::uint64_t{1} << i)) {
        if (used == 0) { min_x = max_x = c.x[i]; min_y = max_y = c.y[i]; }
        else { if (c.x[i] < min_x) min_x = c.x[i]; if (c.x[i] > max_x) max_x = c.x[i];
               if (c.y[i] < min_y) min_y = c.y[i]; if (c.y[i] > max_y) max_y = c.y[i]; }
        members[used++] = i;
    }
    node.count = used;
    node.cx = (static_cast<double>(min_x) + static_cast<double>(max_x)) / 2.0;
    node.cy = (static_cast<double>(min_y) + static_cast<double>(max_y)) / 2.0;
    const double hx = (static_cast<double>(max_x) - static_cast<double>(min_x)) / 2.0;
    const double hy = (static_cast<double>(max_y) - static_cast<double>(min_y)) / 2.0;
    node.radius = std::sqrt(hx * hx + hy * hy);
    if (used == 1) return id;
    const int axis = max_x - min_x >= max_y - min_y ? 0 : 1;
    for (int i = 1; i < used; ++i) { const int value = members[i]; int j = i;
        while (j > 0 && point_less(c, value, members[j - 1], axis)) { members[j] = members[j - 1]; --j; }
        members[j] = value;
    }
    std::uint64_t left_mask = 0, right_mask = 0;
    const int middle = used / 2;
    for (int i = 0; i < used; ++i) if (i < middle) left_mask |= std::uint64_t{1} << members[i];
        else right_mask |= std::uint64_t{1} << members[i];
    const int left = build_node(c, left_mask), right = build_node(c, right_mask);
    c.nodes[id].left = left; c.nodes[id].right = right;
    return id;
}
bool well_separated(const Context& c, int a, int b) {
    const Node& x = c.nodes[a]; const Node& y = c.nodes[b];
    const double r = x.radius > y.radius ? x.radius : y.radius;
    const double dx = x.cx - y.cx, dy = x.cy - y.cy;
    return std::sqrt(dx * dx + dy * dy) - 2.0 * r > static_cast<double>(c.separation) * r;
}
void cross_nodes(Context& c, int a, int b) {
    if (c.overflow) return;
    if (well_separated(c, a, b)) {
        if (c.pair_count >= max_pairs) { c.overflow = true; return; }
        c.left_masks[c.pair_count] = c.nodes[a].mask; c.right_masks[c.pair_count] = c.nodes[b].mask; ++c.pair_count; return;
    }
    if (c.nodes[a].radius > c.nodes[b].radius) {
        cross_nodes(c, c.nodes[a].left, b); cross_nodes(c, c.nodes[a].right, b);
    } else {
        cross_nodes(c, a, c.nodes[b].left); cross_nodes(c, a, c.nodes[b].right);
    }
}
void visit_node(Context& c, int id) {
    const int left = c.nodes[id].left, right = c.nodes[id].right;
    if (left < 0) return;
    visit_node(c, left); visit_node(c, right); cross_nodes(c, left, right);
}
void put_i64(std::uint8_t* out, std::size_t at, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) { out[at + b] = static_cast<std::uint8_t>(bits); bits >>= 8; }
}
}

extern "C" std::int64_t wspd(const std::int64_t* values, std::size_t length,
                              std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 4 || length > 18 || values[0] < 1 || values[0] > max_points ||
        values[1] < 1 || values[1] > 8 || length != 2 + 2 * static_cast<std::size_t>(values[0])) return -1;
    Context c{}; c.point_count = static_cast<int>(values[0]); c.separation = static_cast<int>(values[1]);
    for (int i = 0; i < c.point_count; ++i) {
        const auto x = values[2 + 2 * i], y = values[3 + 2 * i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return -1;
        for (int j = 0; j < i; ++j) if (c.x[j] == x && c.y[j] == y) return -1;
        c.x[i] = x; c.y[i] = y;
    }
    const auto all = (std::uint64_t{1} << c.point_count) - 1;
    visit_node(c, build_node(c, all));
    if (c.overflow) return -2;
    const std::size_t required = 8 + 16 * static_cast<std::size_t>(c.pair_count);
    std::uint8_t staged[max_output_bytes]{};
    put_i64(staged, 0, c.pair_count);
    for (int i = 0; i < c.pair_count; ++i) {
        put_i64(staged, 8 + 16 * static_cast<std::size_t>(i), static_cast<std::int64_t>(c.left_masks[i]));
        put_i64(staged, 16 + 16 * static_cast<std::size_t>(i), static_cast<std::int64_t>(c.right_masks[i]));
    }
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}
