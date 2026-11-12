#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_n = 8, max_q = 12, max_input = 93;
constexpr std::int64_t modulus = 998'244'353;
struct Affine { std::int64_t multiplier, addend; };
struct Node {
    int child[2]{-1, -1};
    int parent = -1;
    bool reversed = false;
    Affine value{}, forward{}, backward{};
};
struct Query { std::int64_t kind, a, b, c, d; };

Affine identity() { return {1, 0}; }
Affine compose(Affine after, Affine before) {
    return {after.multiplier * before.multiplier % modulus,
            (after.multiplier * before.addend + after.addend) % modulus};
}
bool is_aux_root(const std::array<Node, max_n>& nodes, int x) {
    const int parent = nodes[static_cast<std::size_t>(x)].parent;
    return parent < 0 || (nodes[static_cast<std::size_t>(parent)].child[0] != x &&
                          nodes[static_cast<std::size_t>(parent)].child[1] != x);
}
void pull(std::array<Node, max_n>& nodes, int x) {
    const auto& node = nodes[static_cast<std::size_t>(x)];
    const auto left_forward = node.child[0] < 0 ? identity() : nodes[static_cast<std::size_t>(node.child[0])].forward;
    const auto right_forward = node.child[1] < 0 ? identity() : nodes[static_cast<std::size_t>(node.child[1])].forward;
    const auto left_backward = node.child[0] < 0 ? identity() : nodes[static_cast<std::size_t>(node.child[0])].backward;
    const auto right_backward = node.child[1] < 0 ? identity() : nodes[static_cast<std::size_t>(node.child[1])].backward;
    nodes[static_cast<std::size_t>(x)].forward = compose(right_forward, compose(node.value, left_forward));
    nodes[static_cast<std::size_t>(x)].backward = compose(left_backward, compose(node.value, right_backward));
}
void reverse_path(std::array<Node, max_n>& nodes, int x) {
    if (x < 0) return;
    auto& node = nodes[static_cast<std::size_t>(x)];
    std::swap(node.child[0], node.child[1]);
    std::swap(node.forward, node.backward);
    node.reversed = !node.reversed;
}
void push(std::array<Node, max_n>& nodes, int x) {
    if (!nodes[static_cast<std::size_t>(x)].reversed) return;
    reverse_path(nodes, nodes[static_cast<std::size_t>(x)].child[0]);
    reverse_path(nodes, nodes[static_cast<std::size_t>(x)].child[1]);
    nodes[static_cast<std::size_t>(x)].reversed = false;
}
void rotate(std::array<Node, max_n>& nodes, int x) {
    const int p = nodes[static_cast<std::size_t>(x)].parent;
    const int g = nodes[static_cast<std::size_t>(p)].parent;
    const int direction = nodes[static_cast<std::size_t>(p)].child[1] == x;
    const int middle = nodes[static_cast<std::size_t>(x)].child[direction ^ 1];
    if (!is_aux_root(nodes, p))
        nodes[static_cast<std::size_t>(g)].child[nodes[static_cast<std::size_t>(g)].child[1] == p] = x;
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
    for (int y = x; y >= 0;) {
        splay(nodes, y);
        nodes[static_cast<std::size_t>(y)].child[1] = last;
        if (last >= 0) nodes[static_cast<std::size_t>(last)].parent = y;
        pull(nodes, y);
        last = y;
        y = nodes[static_cast<std::size_t>(y)].parent;
    }
    splay(nodes, x);
}
void make_root(std::array<Node, max_n>& nodes, int x) { access(nodes, x); reverse_path(nodes, x); }
int find_root(std::array<Node, max_n>& nodes, int x) {
    access(nodes, x); push(nodes, x);
    while (nodes[static_cast<std::size_t>(x)].child[0] >= 0) {
        x = nodes[static_cast<std::size_t>(x)].child[0]; push(nodes, x);
    }
    splay(nodes, x); return x;
}
bool link_nodes(std::array<Node, max_n>& nodes, int u, int v) {
    if (u == v) return false;
    make_root(nodes, u); if (find_root(nodes, v) == u) return false;
    nodes[static_cast<std::size_t>(u)].parent = v; return true;
}
bool cut_nodes(std::array<Node, max_n>& nodes, int u, int v) {
    if (u == v) return false;
    make_root(nodes, u); access(nodes, v);
    if (nodes[static_cast<std::size_t>(v)].child[0] != u || nodes[static_cast<std::size_t>(u)].child[1] >= 0) return false;
    nodes[static_cast<std::size_t>(v)].child[0] = -1;
    nodes[static_cast<std::size_t>(u)].parent = -1;
    pull(nodes, v); return true;
}
void set_value(std::array<Node, max_n>& nodes, int vertex, Affine value) {
    access(nodes, vertex); nodes[static_cast<std::size_t>(vertex)].value = value; pull(nodes, vertex);
}
bool path_composition(std::array<Node, max_n>& nodes, int u, int v, Affine& result) {
    make_root(nodes, u); if (find_root(nodes, v) != u) return false;
    make_root(nodes, u); access(nodes, v); result = nodes[static_cast<std::size_t>(v)].forward; return true;
}
std::size_t find_dsu(std::array<std::size_t, max_n>& parent, std::size_t item) {
    while (parent[item] != item) { parent[item] = parent[parent[item]]; item = parent[item]; }
    return item;
}
bool connected(const std::array<std::array<bool, max_n>, max_n>& adjacency,
               std::size_t n, std::size_t start, std::size_t target) {
    std::array<bool, max_n> seen{};
    std::array<std::size_t, max_n> stack{};
    std::size_t top = 0; seen[start] = true; stack[top++] = start;
    while (top > 0) {
        const auto u = stack[--top];
        if (u == target) return true;
        for (std::size_t v = 0; v < n; ++v)
            if (adjacency[u][v] && !seen[v]) { seen[v] = true; stack[top++] = v; }
    }
    return false;
}
void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t dynamic_tree_vertex_set_path_composite(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length < 2 + 2 * n + 2 * (n - 1) + 4 * q) return -1;
    std::array<Affine, max_n> values{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto multiplier = input[2 + 2 * i], addend = input[3 + 2 * i];
        if (multiplier < 1 || multiplier >= modulus || addend < 0 || addend >= modulus) return -1;
        values[i] = {multiplier, addend};
    }
    std::array<std::array<bool, max_n>, max_n> adjacency{};
    std::array<std::size_t, max_n> dsu{};
    for (std::size_t i = 0; i < n; ++i) dsu[i] = i;
    std::array<std::size_t, max_n> edge_u{}, edge_v{};
    std::size_t cursor = 2 + 2 * n;
    for (std::size_t edge = 0; edge + 1 < n; ++edge) {
        const auto u_value = input[cursor++], v_value = input[cursor++];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        const auto u = static_cast<std::size_t>(u_value), v = static_cast<std::size_t>(v_value);
        const auto root_u = find_dsu(dsu, u), root_v = find_dsu(dsu, v);
        if (root_u == root_v) return -1;
        dsu[root_v] = root_u; adjacency[u][v] = adjacency[v][u] = true;
        edge_u[edge] = u; edge_v[edge] = v;
    }
    std::array<Query, max_q> queries{};
    std::size_t answer_count = 0;
    for (std::size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        Query current{input[cursor++], 0, 0, 0, 0};
        if (current.kind == 0) {
            if (length - cursor < 4) return -1;
            current.a = input[cursor++]; current.b = input[cursor++];
            current.c = input[cursor++]; current.d = input[cursor++];
            if (current.a < 0 || current.a >= n_value || current.b < 0 || current.b >= n_value ||
                current.c < 0 || current.c >= n_value || current.d < 0 || current.d >= n_value ||
                current.a == current.b || current.c == current.d) return -1;
            const auto u = static_cast<std::size_t>(current.a), v = static_cast<std::size_t>(current.b);
            const auto w = static_cast<std::size_t>(current.c), x = static_cast<std::size_t>(current.d);
            if (!adjacency[u][v]) return -1;
            adjacency[u][v] = adjacency[v][u] = false;
            if (connected(adjacency, n, w, x)) return -1;
            adjacency[w][x] = adjacency[x][w] = true;
        } else if (current.kind == 1) {
            if (length - cursor < 3) return -1;
            current.a = input[cursor++]; current.b = input[cursor++]; current.c = input[cursor++];
            if (current.a < 0 || current.a >= n_value || current.b < 1 || current.b >= modulus ||
                current.c < 0 || current.c >= modulus) return -1;
        } else if (current.kind == 2) {
            if (length - cursor < 3) return -1;
            current.a = input[cursor++]; current.b = input[cursor++]; current.c = input[cursor++];
            if (current.a < 0 || current.a >= n_value || current.b < 0 || current.b >= n_value ||
                current.c < 0 || current.c >= modulus) return -1;
            ++answer_count;
        } else return -1;
        queries[i] = current;
    }
    if (cursor != length) return -1;
    const auto required = 8 * answer_count;
    if (output == nullptr || capacity < required) return -2;

    std::array<Node, max_n> nodes{};
    for (std::size_t i = 0; i < n; ++i) {
        nodes[i].child[0] = nodes[i].child[1] = nodes[i].parent = -1;
        nodes[i].value = nodes[i].forward = nodes[i].backward = values[i];
    }
    for (std::size_t edge = 0; edge + 1 < n; ++edge)
        if (!link_nodes(nodes, static_cast<int>(edge_u[edge]), static_cast<int>(edge_v[edge]))) return -1;
    std::array<std::int64_t, max_q> answers{};
    std::size_t written = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto current = queries[i];
        if (current.kind == 0) {
            if (!cut_nodes(nodes, static_cast<int>(current.a), static_cast<int>(current.b)) ||
                !link_nodes(nodes, static_cast<int>(current.c), static_cast<int>(current.d))) return -1;
        } else if (current.kind == 1) {
            set_value(nodes, static_cast<int>(current.a), {current.b, current.c});
        } else {
            Affine combined{};
            if (!path_composition(nodes, static_cast<int>(current.a), static_cast<int>(current.b), combined)) return -1;
            answers[written++] = (combined.multiplier * current.c + combined.addend) % modulus;
        }
    }
    for (std::size_t i = 0; i < written; ++i) store_le(output, 8 * i, answers[i]);
    return static_cast<std::int64_t>(required);
}
