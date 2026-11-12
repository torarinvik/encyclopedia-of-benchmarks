#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t N = 8, M = 32, MAX_NODES = N + 2 * M;
constexpr std::size_t INPUT_MAX = 2 + N + 3 * M;

struct Op { std::int64_t kind, a, b; };
struct Tree {
    std::array<int, MAX_NODES> left{}, right{}, parent{}, vertex{}, size{}, count{};
    std::array<std::int64_t, MAX_NODES> value{}, sum{};
    std::array<std::uint64_t, MAX_NODES> priority{};
    std::array<int, M> edge_u{}, edge_v{}, arc_uv{}, arc_vu{};
    std::array<bool, M> active{};
    std::size_t next_node = 0, edge_count = 0;
};

std::uint64_t mix(std::uint64_t x) {
    x += UINT64_C(0x9e3779b97f4a7c15);
    x = (x ^ (x >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
    x = (x ^ (x >> 27)) * UINT64_C(0x94d049bb133111eb);
    return x ^ (x >> 31);
}
int node_size(const Tree& t, int x) { return x < 0 ? 0 : t.size[x]; }
int node_count(const Tree& t, int x) { return x < 0 ? 0 : t.count[x]; }
std::int64_t node_sum(const Tree& t, int x) { return x < 0 ? 0 : t.sum[x]; }
void pull(Tree& t, int x) {
    if (x < 0) return;
    t.size[x] = 1 + node_size(t, t.left[x]) + node_size(t, t.right[x]);
    t.count[x] = (t.vertex[x] >= 0 ? 1 : 0) + node_count(t, t.left[x]) + node_count(t, t.right[x]);
    t.sum[x] = t.value[x] + node_sum(t, t.left[x]) + node_sum(t, t.right[x]);
}
int merge(Tree& t, int a, int b) {
    if (a < 0) { if (b >= 0) t.parent[b] = -1; return b; }
    if (b < 0) { t.parent[a] = -1; return a; }
    if (t.priority[a] > t.priority[b]) {
        t.right[a] = merge(t, t.right[a], b);
        if (t.right[a] >= 0) t.parent[t.right[a]] = a;
        pull(t, a); t.parent[a] = -1; return a;
    }
    t.left[b] = merge(t, a, t.left[b]);
    if (t.left[b] >= 0) t.parent[t.left[b]] = b;
    pull(t, b); t.parent[b] = -1; return b;
}
void split(Tree& t, int root, int prefix, int& first, int& rest) {
    if (root < 0) { first = rest = -1; return; }
    if (prefix <= node_size(t, t.left[root])) {
        split(t, t.left[root], prefix, first, rest);
        t.left[root] = rest;
        if (rest >= 0) t.parent[rest] = root;
        pull(t, root); t.parent[root] = -1;
        if (first >= 0) t.parent[first] = -1;
        rest = root;
        return;
    }
    split(t, t.right[root], prefix - node_size(t, t.left[root]) - 1, first, rest);
    t.right[root] = first;
    if (first >= 0) t.parent[first] = root;
    pull(t, root); t.parent[root] = -1;
    if (rest >= 0) t.parent[rest] = -1;
    first = root;
}
int root_of(const Tree& t, int x) { while (t.parent[x] >= 0) x = t.parent[x]; return x; }
int position(const Tree& t, int x) {
    int result = node_size(t, t.left[x]);
    while (t.parent[x] >= 0) {
        const int p = t.parent[x];
        if (t.right[p] == x) result += 1 + node_size(t, t.left[p]);
        x = p;
    }
    return result;
}
int rotate_to(Tree& t, int root, int x) {
    int first, rest;
    split(t, root, position(t, x), first, rest);
    return merge(t, rest, first);
}
bool connected(const bool adjacency[N][N], int start, int target, int n) {
    bool seen[N]{};
    int stack[N], top = 0;
    stack[top++] = start; seen[start] = true;
    while (top) {
        int u = stack[--top];
        if (u == target) return true;
        for (int v = 0; v < n; ++v) if (adjacency[u][v] && !seen[v]) {
            seen[v] = true; stack[top++] = v;
        }
    }
    return false;
}
void initialize(Tree& t, const std::int64_t weight[N], int n) {
    t.left.fill(-1); t.right.fill(-1); t.parent.fill(-1); t.vertex.fill(-1);
    t.size.fill(0); t.count.fill(0); t.value.fill(0); t.sum.fill(0);
    for (int i = 0; i < static_cast<int>(MAX_NODES); ++i) t.priority[i] = mix(static_cast<std::uint64_t>(i));
    for (int i = 0; i < n; ++i) {
        t.vertex[i] = i; t.value[i] = weight[i]; t.size[i] = t.count[i] = 1; t.sum[i] = weight[i];
    }
    t.next_node = static_cast<std::size_t>(n); t.edge_count = 0;
}
void link(Tree& t, int u, int v) {
    int a = rotate_to(t, root_of(t, u), u);
    int b = rotate_to(t, root_of(t, v), v);
    const int uv = static_cast<int>(t.next_node++), vu = static_cast<int>(t.next_node++);
    const int arcs[2] = {uv, vu};
    for (int arc : arcs) { t.left[arc] = t.right[arc] = t.parent[arc] = -1; t.vertex[arc] = -1; t.value[arc] = 0; t.size[arc] = 1; t.count[arc] = 0; t.sum[arc] = 0; }
    int joined = merge(t, merge(t, merge(t, a, uv), b), vu);
    t.parent[joined] = -1;
    const auto e = t.edge_count++;
    t.edge_u[e] = u; t.edge_v[e] = v; t.arc_uv[e] = uv; t.arc_vu[e] = vu; t.active[e] = true;
}
bool cut(Tree& t, int u, int v) {
    int edge = -1;
    for (int i = static_cast<int>(t.edge_count) - 1; i >= 0; --i)
        if (t.active[i] && ((t.edge_u[i] == u && t.edge_v[i] == v) || (t.edge_u[i] == v && t.edge_v[i] == u))) { edge = i; break; }
    if (edge < 0) return false;
    const int first_arc = (t.edge_u[edge] == u && t.edge_v[edge] == v) ? t.arc_uv[edge] : t.arc_vu[edge];
    const int second_arc = first_arc == t.arc_uv[edge] ? t.arc_vu[edge] : t.arc_uv[edge];
    int root = rotate_to(t, root_of(t, first_arc), first_arc), discarded, rest;
    split(t, root, 1, discarded, rest);
    int between, suffix;
    split(t, rest, position(t, second_arc), between, suffix);
    int discarded_second, other;
    split(t, suffix, 1, discarded_second, other);
    if (between >= 0) t.parent[between] = -1;
    if (other >= 0) t.parent[other] = -1;
    t.active[edge] = false;
    return true;
}
void update_weight(Tree& t, int vertex, std::int64_t value) {
    t.value[vertex] = value;
    int path[MAX_NODES], count = 0;
    for (int x = vertex; x >= 0; x = t.parent[x]) path[count++] = x;
    for (int i = 0; i < count; ++i) pull(t, path[i]);
}
void store(std::uint8_t* output, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[at + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t euler_tour_tree(const std::int64_t* input, std::size_t length,
                                          std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 2 || length > INPUT_MAX) return -1;
    const auto nr = input[0], mr = input[1];
    if (nr < 1 || nr > static_cast<std::int64_t>(N) || mr < 1 || mr > static_cast<std::int64_t>(M)) return -1;
    const int n = static_cast<int>(nr), m = static_cast<int>(mr);
    std::size_t cursor = 2;
    std::array<std::int64_t, N> weights{};
    for (int i = 0; i < n; ++i) {
        if (cursor >= length) return -1;
        weights[i] = input[cursor++];
        if (weights[i] < -100 || weights[i] > 100) return -1;
    }
    std::array<Op, M> operations{};
    int query_count = 0;
    for (int i = 0; i < m; ++i) {
        if (cursor >= length) return -1;
        const auto kind = input[cursor++];
        if (kind == 0 || kind == 1) {
            if (cursor + 2 > length) return -1;
            const auto u = input[cursor++], v = input[cursor++];
            if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1;
            operations[i] = {kind, u, v};
        } else if (kind == 2) {
            if (cursor + 2 > length) return -1;
            const auto vertex = input[cursor++], value = input[cursor++];
            if (vertex < 0 || vertex >= n || value < -100 || value > 100) return -1;
            operations[i] = {kind, vertex, value};
        } else if (kind == 3) {
            if (cursor >= length) return -1;
            const auto vertex = input[cursor++];
            if (vertex < 0 || vertex >= n) return -1;
            operations[i] = {kind, vertex, 0}; ++query_count;
        } else return -1;
    }
    if (cursor != length || query_count == 0) return -1;
    bool adjacency[N][N]{};
    for (int i = 0; i < m; ++i) {
        const auto op = operations[i];
        if (op.kind == 0) {
            if (connected(adjacency, static_cast<int>(op.a), static_cast<int>(op.b), n)) return -1;
            adjacency[op.a][op.b] = adjacency[op.b][op.a] = true;
        } else if (op.kind == 1) {
            if (!adjacency[op.a][op.b]) return -1;
            adjacency[op.a][op.b] = adjacency[op.b][op.a] = false;
        }
    }
    const std::size_t required = 16 * static_cast<std::size_t>(query_count);
    if (!output || capacity < required) return -2;
    Tree tree{}; initialize(tree, weights.data(), n);
    std::array<std::int64_t, 2 * M> answers{};
    std::size_t answer_count = 0;
    for (int i = 0; i < m; ++i) {
        const auto op = operations[i];
        if (op.kind == 0) link(tree, static_cast<int>(op.a), static_cast<int>(op.b));
        else if (op.kind == 1) cut(tree, static_cast<int>(op.a), static_cast<int>(op.b));
        else if (op.kind == 2) update_weight(tree, static_cast<int>(op.a), op.b);
        else {
            const int root = root_of(tree, static_cast<int>(op.a));
            answers[answer_count++] = tree.count[root];
            answers[answer_count++] = tree.sum[root];
        }
    }
    for (std::size_t i = 0; i < answer_count; ++i) store(output, 8 * i, answers[i]);
    return static_cast<std::int64_t>(required);
}
