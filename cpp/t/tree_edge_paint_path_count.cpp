#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 16, max_q = 32, max_edges = 15, log_n = 5;

int root_of(int parent[max_n], int value) {
    while (parent[value] != value) {
        parent[value] = parent[parent[value]];
        value = parent[value];
    }
    return value;
}

void point_set(std::int64_t tree[64], int base, int index, std::int64_t value) {
    int position = base + index;
    tree[position] = value;
    for (position /= 2; position > 0; position /= 2)
        tree[position] = tree[2 * position] + tree[2 * position + 1];
}

std::int64_t range_sum(const std::int64_t tree[64], int base, int left, int right) {
    if (left > right) return 0;
    int l = base + left, r = base + right + 1;
    std::int64_t total = 0;
    while (l < r) {
        if (l & 1) total += tree[l++];
        if (r & 1) total += tree[--r];
        l /= 2;
        r /= 2;
    }
    return total;
}

int lca(int a, int b, const int depth[max_n], const int parent[max_n],
        const int ancestor[log_n][max_n]) {
    if (depth[a] < depth[b]) { const int t = a; a = b; b = t; }
    int difference = depth[a] - depth[b];
    for (int bit = 0; bit < log_n; ++bit)
        if ((difference >> bit) & 1) a = ancestor[bit][a];
    if (a == b) return a;
    for (int bit = log_n - 1; bit >= 0; --bit) {
        if (ancestor[bit][a] != ancestor[bit][b]) {
            a = ancestor[bit][a];
            b = ancestor[bit][b];
        }
    }
    return parent[a];
}

std::int64_t solve(const std::int64_t* input, std::size_t length) {
    if (!input || length < 2 || length > 129) return -1;
    if (input[0] < 1 || input[0] > max_n || input[1] < 0 || input[1] > max_q) return -1;
    const int n = static_cast<int>(input[0]), q = static_cast<int>(input[1]);
    const int m = n - 1;
    if (length != static_cast<std::size_t>(2 + 2 * m + 3 * q)) return -1;

    int edge_u[max_edges], edge_v[max_edges], dsu[max_n];
    for (int i = 0; i < n; ++i) dsu[i] = i;
    std::size_t cursor = 2;
    for (int e = 0; e < m; ++e) {
        const auto u = input[cursor++], v = input[cursor++];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v) return -1;
        edge_u[e] = static_cast<int>(u);
        edge_v[e] = static_cast<int>(v);
        const int ru = root_of(dsu, edge_u[e]), rv = root_of(dsu, edge_v[e]);
        if (ru == rv) return -1;
        dsu[ru] = rv;
    }
    for (int v = 1; v < n; ++v) if (root_of(dsu, v) != root_of(dsu, 0)) return -1;

    int parent[max_n] = {}, depth[max_n] = {}, first[max_n] = {};
    int down[max_edges], up[max_edges], visited[max_n] = {};
    int stack_node[max_n], stack_parent[max_n], stack_in[max_n], stack_cursor[max_n];
    int occurrence_count = 0, top = 0;
    visited[0] = 1;
    stack_node[0] = 0; stack_parent[0] = -1; stack_in[0] = -1; stack_cursor[0] = 0;
    while (top >= 0) {
        const int node = stack_node[top];
        int found = 0;
        while (stack_cursor[top] < m) {
            const int edge = stack_cursor[top]++;
            if (edge_u[edge] != node && edge_v[edge] != node) continue;
            const int child = edge_u[edge] == node ? edge_v[edge] : edge_u[edge];
            if (child == stack_parent[top]) continue;
            if (visited[child]) return -1;
            visited[child] = 1; parent[child] = node; depth[child] = depth[node] + 1;
            down[edge] = occurrence_count++;
            first[child] = occurrence_count;
            ++top; stack_node[top] = child; stack_parent[top] = node;
            stack_in[top] = edge; stack_cursor[top] = 0;
            found = 1; break;
        }
        if (!found) {
            const int incoming = stack_in[top--];
            if (incoming >= 0) up[incoming] = occurrence_count++;
        }
    }

    int ancestor[log_n][max_n] = {};
    for (int v = 0; v < n; ++v) ancestor[0][v] = parent[v];
    for (int k = 1; k < log_n; ++k)
        for (int v = 0; v < n; ++v) ancestor[k][v] = ancestor[k - 1][ancestor[k - 1][v]];
    int base = 1;
    while (base < occurrence_count) base *= 2;
    std::int64_t forward[64] = {}, backward[64] = {};
    int painted[max_edges] = {};
    std::int64_t total = 0;
    for (int i = 0; i < q; ++i) {
        const auto kind = input[cursor++], a = input[cursor++], b = input[cursor++];
        if (kind == 0) {
            if (a < 0 || a >= m || b != 0) return -1;
            if (!painted[a]) {
                painted[a] = 1;
                point_set(forward, base, down[a], 1);
                point_set(backward, base, up[a], 1);
            }
        } else if (kind == 1) {
            if (a < 0 || a >= n || b < 0 || b >= n) return -1;
            const int common = lca(static_cast<int>(a), static_cast<int>(b), depth, parent, ancestor);
            const int left_a = first[common], right_a = first[a] - 1;
            const int left_b = first[common], right_b = first[b] - 1;
            total += range_sum(forward, base, left_a, right_a) - range_sum(backward, base, left_a, right_a);
            total += range_sum(forward, base, left_b, right_b) - range_sum(backward, base, left_b, right_b);
        } else return -1;
    }
    return total;
}
}

extern "C" std::int64_t tree_edge_paint_path_count(const std::int64_t* input,
        std::size_t length) noexcept {
    return solve(input, length);
}
