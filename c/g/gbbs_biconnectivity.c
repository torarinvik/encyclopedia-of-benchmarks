/* Clean-room bounded GBBS Tarjan-Vishkin biconnectivity profile; see LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_M = 24, MAX_INPUT = 2 + 2 * MAX_M };

static int is_tree_edge(size_t u, size_t v, const size_t *parent) {
    return parent[u] == v || parent[v] == u;
}

static int critical_edge(size_t u, size_t v, const size_t *parent,
                         const uint8_t *critical) {
    if (parent[u] == v) return critical[u] != 0;
    if (parent[v] == u) return critical[v] != 0;
    return 0;
}

static void assign_parents(size_t n, const uint8_t adjacent[MAX_N][MAX_N],
                           size_t *parent, uint8_t *seen) {
    size_t frontier[MAX_N], next[MAX_N], candidate[MAX_N];
    for (size_t root = 0; root < n; ++root) {
        if (seen[root]) continue;
        size_t frontier_count = 1;
        frontier[0] = root;
        seen[root] = 1;
        parent[root] = root;
        while (frontier_count != 0) {
            uint8_t has_candidate[MAX_N] = {0};
            for (size_t i = 0; i < frontier_count; ++i) {
                const size_t vertex = frontier[i];
                for (size_t other = 0; other < n; ++other) {
                    if (adjacent[vertex][other] && !seen[other]) {
                        if (!has_candidate[other] || vertex < candidate[other])
                            candidate[other] = vertex;
                        has_candidate[other] = 1;
                    }
                }
            }
            size_t next_count = 0;
            for (size_t other = 0; other < n; ++other) {
                if (has_candidate[other]) {
                    parent[other] = candidate[other];
                    seen[other] = 1;
                    next[next_count++] = other;
                }
            }
            for (size_t i = 0; i < next_count; ++i) frontier[i] = next[i];
            frontier_count = next_count;
        }
    }
}

static void assign_preorder(size_t n, const size_t *parent,
                            size_t *preorder_number, size_t *preorder,
                            size_t *subtree_size) {
    size_t stack[MAX_N];
    size_t global_count = 0;
    /* Keep each tree's preorder numbers local, like the source multi-forest. */
    for (size_t root = 0; root < n; ++root) {
        if (parent[root] != root) continue;
        size_t top = 0, count = 0, begin = global_count;
        stack[top++] = root;
        while (top != 0) {
            const size_t vertex = stack[--top];
            preorder_number[vertex] = count;
            preorder[global_count++] = vertex;
            ++count;
            for (size_t child = n; child-- > 0;) {
                if (child != vertex && parent[child] == vertex) stack[top++] = child;
            }
        }
        for (size_t i = global_count; i-- > begin;) {
            const size_t vertex = preorder[i];
            if (parent[vertex] != vertex)
                subtree_size[parent[vertex]] += subtree_size[vertex];
        }
    }
}

static void store_bytes(uint8_t *output, const uint8_t *labels,
                        size_t edge_count) {
    for (size_t edge = 0; edge < edge_count; ++edge) output[edge] = labels[edge];
}

int64_t gbbs_biconnectivity(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
    }
    if (output == NULL || capacity < m) return -2;

    size_t parent[MAX_N], preorder_number[MAX_N], preorder[MAX_N];
    size_t subtree_size[MAX_N];
    uint8_t seen[MAX_N] = {0}, critical[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        parent[vertex] = vertex;
        preorder_number[vertex] = 0;
        subtree_size[vertex] = 1;
    }
    assign_parents(n, adjacent, parent, seen);
    assign_preorder(n, parent, preorder_number, preorder, subtree_size);

    size_t low[MAX_N], high[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        low[vertex] = preorder_number[vertex];
        high[vertex] = preorder_number[vertex] + subtree_size[vertex] - 1;
    }
    for (size_t edge = 0; edge < m; ++edge) {
        const size_t u = (size_t)input[2 + 2 * edge];
        const size_t v = (size_t)input[3 + 2 * edge];
        if (!is_tree_edge(u, v, parent)) {
            const size_t pu = preorder_number[u], pv = preorder_number[v];
            if (pu < low[v]) low[v] = pu;
            else if (pu > high[v]) high[v] = pu;
            if (pv < low[u]) low[u] = pv;
            else if (pv > high[u]) high[u] = pv;
        }
    }
    /* The source's leaf-fix propagates each child's low/high labels upward. */
    for (size_t i = n; i-- > 0;) {
        const size_t vertex = preorder[i];
        if (parent[vertex] != vertex) {
            const size_t p = parent[vertex];
            if (low[vertex] < low[p]) low[p] = low[vertex];
            if (high[vertex] > high[p]) high[p] = high[vertex];
        }
    }
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const size_t p = parent[vertex];
        if (vertex != p && low[vertex] >= preorder_number[p] &&
            high[vertex] < preorder_number[p] + subtree_size[p])
            critical[vertex] = 1;
    }

    size_t component[MAX_N], queue[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) component[vertex] = SIZE_MAX;
    for (size_t root = 0; root < n; ++root) {
        if (component[root] != SIZE_MAX) continue;
        size_t head = 0, tail = 0;
        component[root] = root;
        queue[tail++] = root;
        while (head < tail) {
            const size_t vertex = queue[head++];
            for (size_t other = 0; other < n; ++other) {
                if (!adjacent[vertex][other] ||
                    critical_edge(vertex, other, parent, critical) ||
                    component[other] != SIZE_MAX) continue;
                component[other] = root;
                queue[tail++] = other;
            }
        }
    }

    size_t raw_label[MAX_M];
    uint8_t labels[MAX_M];
    for (size_t edge = 0; edge < m; ++edge) {
        const size_t u = (size_t)input[2 + 2 * edge];
        const size_t v = (size_t)input[3 + 2 * edge];
        if (parent[u] == v && critical[u]) raw_label[edge] = component[u];
        else if (parent[v] == u && critical[v]) raw_label[edge] = component[v];
        else raw_label[edge] = component[u];
    }
    for (size_t edge = 0; edge < m; ++edge) {
        size_t canonical = m;
        for (size_t other = 0; other < m; ++other) {
            if (raw_label[other] == raw_label[edge] && other < canonical) canonical = other;
        }
        labels[edge] = (uint8_t)canonical;
    }
    store_bytes(output, labels, m);
    return (int64_t)m;
}
