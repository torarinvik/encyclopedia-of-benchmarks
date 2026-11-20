#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_segments = 8, max_depth = 8, max_nodes = 2048, max_input = 35;
struct Node {
    int parent = -1, quadrant = -1, depth = 0;
    int xmin = 0, ymin = 0, xmax = 0, ymax = 0;
    std::array<int, 4> child{-1, -1, -1, -1};
    std::array<int, max_segments> ids{};
    int id_count = 0;
};
struct State {
    std::array<Node, max_nodes> nodes{};
    std::array<std::array<int, 4>, max_segments> segments{};
    int used = 1;
};

std::int64_t orient(std::int64_t ax, std::int64_t ay, std::int64_t bx,
                    std::int64_t by, std::int64_t cx, std::int64_t cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}
bool between(std::int64_t a, std::int64_t b, std::int64_t p) {
    return (a <= p && p <= b) || (b <= p && p <= a);
}
bool on_segment(std::int64_t ax, std::int64_t ay, std::int64_t bx,
                std::int64_t by, std::int64_t px, std::int64_t py) {
    return between(ax, bx, px) && between(ay, by, py);
}
bool segments_intersect(std::int64_t ax, std::int64_t ay, std::int64_t bx,
                        std::int64_t by, std::int64_t cx, std::int64_t cy,
                        std::int64_t dx, std::int64_t dy) {
    const auto ab_c = orient(ax, ay, bx, by, cx, cy);
    const auto ab_d = orient(ax, ay, bx, by, dx, dy);
    const auto cd_a = orient(cx, cy, dx, dy, ax, ay);
    const auto cd_b = orient(cx, cy, dx, dy, bx, by);
    if (((ab_c < 0 && ab_d > 0) || (ab_c > 0 && ab_d < 0)) &&
        ((cd_a < 0 && cd_b > 0) || (cd_a > 0 && cd_b < 0))) return true;
    return (ab_c == 0 && on_segment(ax, ay, bx, by, cx, cy)) ||
           (ab_d == 0 && on_segment(ax, ay, bx, by, dx, dy)) ||
           (cd_a == 0 && on_segment(cx, cy, dx, dy, ax, ay)) ||
           (cd_b == 0 && on_segment(cx, cy, dx, dy, bx, by));
}
bool intersects_box(const State& state, int sid, const Node& cell) {
    const auto& s = state.segments[sid];
    const std::int64_t x0 = 2 * s[0], y0 = 2 * s[1], x1 = 2 * s[2], y1 = 2 * s[3];
    const auto lx = cell.xmin, ly = cell.ymin, hx = cell.xmax, hy = cell.ymax;
    if ((lx <= x0 && x0 <= hx && ly <= y0 && y0 <= hy) ||
        (lx <= x1 && x1 <= hx && ly <= y1 && y1 <= hy)) return true;
    return segments_intersect(x0,y0,x1,y1,lx,ly,hx,ly) ||
           segments_intersect(x0,y0,x1,y1,hx,ly,hx,hy) ||
           segments_intersect(x0,y0,x1,y1,hx,hy,lx,hy) ||
           segments_intersect(x0,y0,x1,y1,lx,hy,lx,ly);
}
void make_node(State& state, int id, int parent, int q, int depth,
               int xmin, int ymin, int xmax, int ymax) {
    Node& node = state.nodes[id];
    node.parent = parent; node.quadrant = q; node.depth = depth;
    node.xmin = xmin; node.ymin = ymin; node.xmax = xmax; node.ymax = ymax;
    node.child.fill(-1); node.id_count = 0;
}
bool insert(State& state, int node_id, int sid, int threshold) {
    Node& node = state.nodes[node_id];
    if (node.child[0] >= 0) {
        for (int q = 0; q < 4; ++q) {
            const int child = node.child[q];
            if (intersects_box(state, sid, state.nodes[child]) &&
                !insert(state, child, sid, threshold)) return false;
        }
        return true;
    }
    if (node.id_count >= max_segments) return false;
    node.ids[node.id_count++] = sid;
    if (node.id_count <= threshold) return true;
    if (node.depth >= max_depth || state.used + 4 > max_nodes) return false;

    const auto old_ids = node.ids;
    const int old_count = node.id_count, base = state.used;
    const int xmin = node.xmin, ymin = node.ymin, xmax = node.xmax, ymax = node.ymax;
    const int mx = xmin + (xmax - xmin) / 2, my = ymin + (ymax - ymin) / 2;
    const int depth = node.depth + 1;
    for (int q = 0; q < 4; ++q) {
        const int x0 = q % 2 == 0 ? xmin : mx;
        const int x1 = q % 2 == 0 ? mx : xmax;
        const int y0 = q < 2 ? my : ymin;
        const int y1 = q < 2 ? ymax : my;
        make_node(state, base + q, node_id, q, depth, x0, y0, x1, y1);
    }
    state.used += 4;
    state.nodes[node_id].child = {base, base + 1, base + 2, base + 3};
    state.nodes[node_id].id_count = 0;
    for (int i = 0; i < old_count; ++i) for (int q = 0; q < 4; ++q) {
        const int child = base + q;
        if (intersects_box(state, old_ids[i], state.nodes[child]) &&
            !insert(state, child, old_ids[i], threshold)) return false;
    }
    return true;
}
void preorder(const State& state, int id, std::array<int, max_nodes>& order, int& count) {
    order[count++] = id;
    if (state.nodes[id].child[0] >= 0)
        for (int child : state.nodes[id].child) preorder(state, child, order, count);
}
void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t pmr_edge_quadtree(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 0 || input[0] > max_segments || input[1] < 1 || input[1] > max_segments) return -1;
    const int count = static_cast<int>(input[0]), threshold = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 4 * count)) return -1;
    State state{};
    for (int i = 0; i < count; ++i) {
        for (int k = 0; k < 4; ++k) {
            const auto value = input[2 + 4 * i + k];
            if (value < 0 || value > 255) return -1;
            state.segments[i][k] = static_cast<int>(value);
        }
        if (state.segments[i][0] == state.segments[i][2] &&
            state.segments[i][1] == state.segments[i][3]) return -1;
    }
    make_node(state, 0, -1, -1, 0, -1, -1, 511, 511);
    for (int sid = 0; sid < count; ++sid) if (!insert(state, 0, sid, threshold)) return -1;

    std::array<int, max_nodes> order{}, remap{};
    int node_count = 0;
    preorder(state, 0, order, node_count);
    std::size_t bytes = 16;
    for (int i = 0; i < node_count; ++i) bytes += 32 + 8 * state.nodes[order[i]].id_count;
    if (output == nullptr || capacity < bytes) return -2;
    for (int i = 0; i < node_count; ++i) remap[order[i]] = i;
    store_le(output, 0, node_count); store_le(output, 8, count);
    std::size_t cursor = 16;
    for (int i = 0; i < node_count; ++i) {
        const Node& node = state.nodes[order[i]];
        store_le(output, cursor, node.parent < 0 ? -1 : remap[node.parent]); cursor += 8;
        store_le(output, cursor, node.quadrant); cursor += 8;
        store_le(output, cursor, node.depth); cursor += 8;
        store_le(output, cursor, node.id_count); cursor += 8;
        for (int j = 0; j < node.id_count; ++j) { store_le(output, cursor, node.ids[j]); cursor += 8; }
    }
    return static_cast<std::int64_t>(bytes);
}
