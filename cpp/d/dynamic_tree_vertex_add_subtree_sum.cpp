#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_n = 32, max_q = 64;
constexpr std::size_t max_input = 3 * max_n + 5 * max_q + 1;
constexpr std::int64_t max_value = 1'000;
struct Node {
    int child[2] = {-1, -1};
    int parent = -1;
    bool reversed = false;
    std::int64_t value = 0, virtual_sum = 0, sum = 0;
};

bool is_aux_root(const std::array<Node, max_n>& nodes, int x) {
    const int p = nodes[static_cast<std::size_t>(x)].parent;
    return p < 0 || (nodes[static_cast<std::size_t>(p)].child[0] != x &&
                     nodes[static_cast<std::size_t>(p)].child[1] != x);
}
std::int64_t node_sum(const std::array<Node, max_n>& nodes, int x) {
    return x < 0 ? 0 : nodes[static_cast<std::size_t>(x)].sum;
}
void pull(std::array<Node, max_n>& nodes, int x) {
    auto& node = nodes[static_cast<std::size_t>(x)];
    node.sum = node.value + node.virtual_sum + node_sum(nodes, node.child[0]) + node_sum(nodes, node.child[1]);
}
void toggle_reverse(std::array<Node, max_n>& nodes, int x) {
    if (x < 0) return;
    auto& node = nodes[static_cast<std::size_t>(x)];
    std::swap(node.child[0], node.child[1]);
    node.reversed = !node.reversed;
}
void push(std::array<Node, max_n>& nodes, int x) {
    if (!nodes[static_cast<std::size_t>(x)].reversed) return;
    toggle_reverse(nodes, nodes[static_cast<std::size_t>(x)].child[0]);
    toggle_reverse(nodes, nodes[static_cast<std::size_t>(x)].child[1]);
    nodes[static_cast<std::size_t>(x)].reversed = false;
}
void rotate(std::array<Node, max_n>& nodes, int x) {
    const int p = nodes[static_cast<std::size_t>(x)].parent;
    const int g = nodes[static_cast<std::size_t>(p)].parent;
    const int direction = nodes[static_cast<std::size_t>(p)].child[1] == x;
    const int middle = nodes[static_cast<std::size_t>(x)].child[direction ^ 1];
    if (!is_aux_root(nodes, p)) nodes[static_cast<std::size_t>(g)].child[
        nodes[static_cast<std::size_t>(g)].child[1] == p] = x;
    nodes[static_cast<std::size_t>(x)].parent = g;
    nodes[static_cast<std::size_t>(x)].child[direction ^ 1] = p;
    nodes[static_cast<std::size_t>(p)].parent = x;
    nodes[static_cast<std::size_t>(p)].child[direction] = middle;
    if (middle >= 0) nodes[static_cast<std::size_t>(middle)].parent = p;
    pull(nodes, p); pull(nodes, x);
}
void splay(std::array<Node, max_n>& nodes, int x) {
    std::array<int, max_n> stack{};
    std::size_t count = 0;
    int y = x;
    stack[count++] = y;
    while (!is_aux_root(nodes, y)) { y = nodes[static_cast<std::size_t>(y)].parent; stack[count++] = y; }
    while (count > 0) push(nodes, stack[--count]);
    while (!is_aux_root(nodes, x)) {
        const int p = nodes[static_cast<std::size_t>(x)].parent;
        if (!is_aux_root(nodes, p)) {
            const int g = nodes[static_cast<std::size_t>(p)].parent;
            const bool zigzig = (nodes[static_cast<std::size_t>(p)].child[0] == x) ==
                                (nodes[static_cast<std::size_t>(g)].child[0] == p);
            rotate(nodes, zigzig ? p : x);
        }
        rotate(nodes, x);
    }
}
void access(std::array<Node, max_n>& nodes, int x) {
    int last = -1;
    for (int y = x; y >= 0; y = nodes[static_cast<std::size_t>(y)].parent) {
        auto& node = nodes[static_cast<std::size_t>(y)];
        splay(nodes, y);
        const int old_right = node.child[1];
        node.virtual_sum += node_sum(nodes, old_right) - node_sum(nodes, last);
        node.child[1] = last;
        if (last >= 0) nodes[static_cast<std::size_t>(last)].parent = y;
        pull(nodes, y);
        last = y;
    }
    splay(nodes, x);
}
void make_root(std::array<Node, max_n>& nodes, int x) { access(nodes, x); toggle_reverse(nodes, x); }
int find_root(std::array<Node, max_n>& nodes, int x) {
    access(nodes, x); push(nodes, x);
    while (nodes[static_cast<std::size_t>(x)].child[0] >= 0) {
        x = nodes[static_cast<std::size_t>(x)].child[0]; push(nodes, x);
    }
    splay(nodes, x); return x;
}
bool link_nodes(std::array<Node, max_n>& nodes, int u, int v) {
    if (u == v) return false;
    make_root(nodes, u);
    if (find_root(nodes, v) == u) return false;
    access(nodes, v);
    nodes[static_cast<std::size_t>(u)].parent = v;
    nodes[static_cast<std::size_t>(v)].virtual_sum += nodes[static_cast<std::size_t>(u)].sum;
    pull(nodes, v);
    return true;
}
bool cut_nodes(std::array<Node, max_n>& nodes, int u, int v) {
    if (u == v) return false;
    make_root(nodes, u); access(nodes, v);
    if (nodes[static_cast<std::size_t>(v)].child[0] != u || nodes[static_cast<std::size_t>(u)].child[1] >= 0) return false;
    nodes[static_cast<std::size_t>(v)].child[0] = -1;
    nodes[static_cast<std::size_t>(u)].parent = -1;
    pull(nodes, v); return true;
}
std::int64_t subtree_side_sum(std::array<Node, max_n>& nodes, int vertex, int parent) {
    make_root(nodes, parent); access(nodes, vertex);
    if (nodes[static_cast<std::size_t>(vertex)].child[0] != parent ||
        nodes[static_cast<std::size_t>(parent)].child[1] >= 0) return -1;
    return nodes[static_cast<std::size_t>(vertex)].value + nodes[static_cast<std::size_t>(vertex)].virtual_sum;
}
void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t dynamic_tree_vertex_add_subtree_sum(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (!input || length < 3 || length > max_input) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) || q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 3 * n + 5 * q) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2 + i] < 0 || input[2 + i] > max_value) return -1;
    const std::size_t edge_start = 2 + n, operation_start = edge_start + 2 * (n - 1);
    for (std::size_t i = 0; i < n - 1; ++i) {
        const auto u = input[edge_start + 2 * i], v = input[edge_start + 2 * i + 1];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value || u == v) return -1;
    }
    for (std::size_t i = 0; i < q; ++i) {
        const std::size_t at = operation_start + 5 * i;
        const auto kind = input[at], a = input[at + 1], b = input[at + 2], c = input[at + 3], d = input[at + 4];
        if (kind == 0) {
            if (a < 0 || a >= n_value || b < 0 || b >= n_value || c < 0 || c >= n_value || d < 0 || d >= n_value || a == b || c == d) return -1;
        } else if (kind == 1) {
            if (a < 0 || a >= n_value || b < 0 || b > max_value || c != 0 || d != 0) return -1;
        } else if (kind == 2) {
            if (a < 0 || a >= n_value || b < 0 || b >= n_value || c != 0 || d != 0) return -1;
        } else return -1;
    }
    std::array<Node, max_n> nodes{};
    for (std::size_t i = 0; i < n; ++i) nodes[i].value = nodes[i].sum = input[2 + i];
    for (std::size_t i = 0; i < n - 1; ++i)
        if (!link_nodes(nodes, static_cast<int>(input[edge_start + 2 * i]), static_cast<int>(input[edge_start + 2 * i + 1]))) return -1;
    std::array<std::int64_t, max_q> answers{};
    std::size_t answer_count = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const std::size_t at = operation_start + 5 * i;
        const int kind = static_cast<int>(input[at]), a = static_cast<int>(input[at + 1]), b = static_cast<int>(input[at + 2]);
        if (kind == 0) {
            const int c = static_cast<int>(input[at + 3]), d = static_cast<int>(input[at + 4]);
            if (!cut_nodes(nodes, a, b) || !link_nodes(nodes, c, d)) return -1;
        } else if (kind == 1) {
            access(nodes, a); nodes[static_cast<std::size_t>(a)].value += b; pull(nodes, a);
        } else {
            const auto answer = subtree_side_sum(nodes, a, b);
            if (answer < 0) return -1;
            answers[answer_count++] = answer;
        }
    }
    const std::size_t output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (!output || capacity < output_bytes)) return -2;
    for (std::size_t i = 0; i < answer_count; ++i) put_i64_le(output, 8 * i, answers[i]);
    return static_cast<std::int64_t>(output_bytes);
}
