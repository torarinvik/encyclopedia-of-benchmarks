#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_n = 16, max_q = 64, max_input = 210;
struct Node { int child[2]; int parent; bool reversed; std::int64_t value, sum; };

bool is_aux_root(const std::array<Node, max_n>& nodes, int x) {
    int p = nodes[static_cast<std::size_t>(x)].parent;
    return p < 0 || (nodes[static_cast<std::size_t>(p)].child[0] != x &&
                     nodes[static_cast<std::size_t>(p)].child[1] != x);
}
void pull(std::array<Node, max_n>& nodes, int x) {
    const auto& node = nodes[static_cast<std::size_t>(x)];
    std::int64_t left = node.child[0] < 0 ? 0 : nodes[static_cast<std::size_t>(node.child[0])].sum;
    std::int64_t right = node.child[1] < 0 ? 0 : nodes[static_cast<std::size_t>(node.child[1])].sum;
    nodes[static_cast<std::size_t>(x)].sum = node.value + left + right;
}
void toggle_reverse(std::array<Node, max_n>& nodes, int x) {
    if (x < 0) return;
    auto& node = nodes[static_cast<std::size_t>(x)];
    std::swap(node.child[0], node.child[1]); node.reversed = !node.reversed;
}
void push(std::array<Node, max_n>& nodes, int x) {
    auto& node = nodes[static_cast<std::size_t>(x)];
    if (!node.reversed) return;
    toggle_reverse(nodes, node.child[0]); toggle_reverse(nodes, node.child[1]); node.reversed = false;
}
void rotate(std::array<Node, max_n>& nodes, int x) {
    int p = nodes[static_cast<std::size_t>(x)].parent;
    int g = nodes[static_cast<std::size_t>(p)].parent;
    int direction = nodes[static_cast<std::size_t>(p)].child[1] == x;
    int middle = nodes[static_cast<std::size_t>(x)].child[direction ^ 1];
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
    std::array<int, max_n> stack{}; std::size_t count = 0; int y = x;
    stack[count++] = y;
    while (!is_aux_root(nodes, y)) { y = nodes[static_cast<std::size_t>(y)].parent; stack[count++] = y; }
    while (count > 0) push(nodes, stack[--count]);
    while (!is_aux_root(nodes, x)) {
        int p = nodes[static_cast<std::size_t>(x)].parent;
        if (!is_aux_root(nodes, p)) {
            int g = nodes[static_cast<std::size_t>(p)].parent;
            bool zigzig = (nodes[static_cast<std::size_t>(p)].child[0] == x) ==
                          (nodes[static_cast<std::size_t>(g)].child[0] == p);
            rotate(nodes, zigzig ? p : x);
        }
        rotate(nodes, x);
    }
}
void access(std::array<Node, max_n>& nodes, int x) {
    int last = -1;
    for (int y = x; y >= 0; y = nodes[static_cast<std::size_t>(y)].parent) {
        splay(nodes, y); nodes[static_cast<std::size_t>(y)].child[1] = last;
        if (last >= 0) nodes[static_cast<std::size_t>(last)].parent = y;
        pull(nodes, y); last = y;
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
std::int64_t link_nodes(std::array<Node, max_n>& nodes, int u, int v) {
    if (u == v) return 0;
    make_root(nodes, u); if (find_root(nodes, v) == u) return 0;
    nodes[static_cast<std::size_t>(u)].parent = v; return 1;
}
std::int64_t cut_nodes(std::array<Node, max_n>& nodes, int u, int v) {
    if (u == v) return 0;
    make_root(nodes, u); access(nodes, v);
    if (nodes[static_cast<std::size_t>(v)].child[0] != u ||
        nodes[static_cast<std::size_t>(u)].child[1] >= 0) return 0;
    nodes[static_cast<std::size_t>(v)].child[0] = -1;
    nodes[static_cast<std::size_t>(u)].parent = -1; pull(nodes, v); return 1;
}
std::int64_t path_sum(std::array<Node, max_n>& nodes, int u, int v) {
    make_root(nodes, u); if (find_root(nodes, v) != u) return -1;
    make_root(nodes, u); access(nodes, v); return nodes[static_cast<std::size_t>(v)].sum;
}
void put_i64(std::uint8_t* out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) out[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t link_cut_tree(const std::int64_t* input, std::size_t input_length,
                                      std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (!input || input_length < 2 || input_length > max_input) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (input_length != 2 + n + 3 * q) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2 + i] < 0 || input[2 + i] > 1000000) return -1;
    const std::size_t operations_at = 2 + n;
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = input[operations_at + 3 * i], u = input[operations_at + 3 * i + 1];
        const auto v = input[operations_at + 3 * i + 2];
        if (op < 0 || op > 2 || u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
    }
    if (!output || output_capacity < 8 * q) return -2;
    std::array<Node, max_n> nodes{};
    for (std::size_t i = 0; i < n; ++i) {
        nodes[i].child[0] = nodes[i].child[1] = nodes[i].parent = -1;
        nodes[i].value = nodes[i].sum = input[2 + i];
    }
    for (std::size_t i = 0; i < q; ++i) {
        const std::size_t at = operations_at + 3 * i;
        const int op = static_cast<int>(input[at]), u = static_cast<int>(input[at + 1]), v = static_cast<int>(input[at + 2]);
        const auto result = op == 0 ? link_nodes(nodes, u, v) : op == 1 ? cut_nodes(nodes, u, v) : path_sum(nodes, u, v);
        put_i64(output, 8 * i, result);
    }
    return static_cast<std::int64_t>(8 * q);
}
