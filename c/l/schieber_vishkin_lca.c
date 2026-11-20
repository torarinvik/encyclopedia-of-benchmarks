#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 256
#define MAX_QUERIES 1024
#define MAX_ARCS (2 * (MAX_NODES - 1))
#define MAX_INPUT (4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES)

static uint32_t sv_lowbit(uint32_t value) {
    return value & (0u - value);
}

static uint32_t sv_highbit(uint32_t value) {
    uint32_t bit = 0;
    while (value != 0) {
        bit = value;
        value >>= 1;
    }
    return bit;
}

int64_t schieber_vishkin_lca(const int64_t *input, size_t length,
    uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT + 1) return -1;
    if (input[0] < 1 || input[0] > MAX_NODES) return -1;
    const size_t n = (size_t)input[0];
    if (input[1] < 0 || input[1] >= (int64_t)n ||
        input[2] != (int64_t)(n - 1) || input[3] < 0 || input[3] > MAX_QUERIES) return -1;
    const size_t m = (size_t)input[2], q = (size_t)input[3];
    const size_t query_offset = 4 + 2 * m;
    if (length != query_offset + 2 * q) return -1;
    const size_t root = (size_t)input[1];

    int head[MAX_NODES], arc_to[MAX_ARCS], arc_next[MAX_ARCS];
    int parent[MAX_NODES], depth[MAX_NODES], order[MAX_NODES];
    int stack_node[MAX_NODES], stack_arc[MAX_NODES];
    size_t preorder[MAX_NODES];
    uint32_t inlabel[MAX_NODES], ascendant[MAX_NODES];
    int path_head[MAX_NODES];
    uint8_t answers[MAX_QUERIES];
    for (size_t i = 0; i < n; ++i) {
        head[i] = -1;
        parent[i] = -2;
    }

    size_t arcs = 0;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t a64 = input[4 + 2 * edge], b64 = input[5 + 2 * edge];
        if (a64 < 0 || a64 >= (int64_t)n || b64 < 0 || b64 >= (int64_t)n || a64 == b64)
            return -1;
        const size_t a = (size_t)a64, b = (size_t)b64;
        arc_to[arcs] = (int)b; arc_next[arcs] = head[a]; head[a] = (int)arcs++;
        arc_to[arcs] = (int)a; arc_next[arcs] = head[b]; head[b] = (int)arcs++;
    }
    for (size_t query = 0; query < q; ++query) {
        for (size_t side = 0; side < 2; ++side) {
            const int64_t node = input[query_offset + 2 * query + side];
            if (node < 0 || node >= (int64_t)n) return -1;
        }
    }

    size_t reached = 1, top = 1;
    parent[root] = -1;
    depth[root] = 0;
    preorder[root] = 1;
    order[0] = (int)root;
    stack_node[0] = (int)root;
    stack_arc[0] = head[root];
    while (top > 0) {
        const size_t slot = top - 1;
        const size_t node = (size_t)stack_node[slot];
        const int arc = stack_arc[slot];
        if (arc < 0) {
            --top;
            continue;
        }
        stack_arc[slot] = arc_next[arc];
        const size_t neighbor = (size_t)arc_to[arc];
        if ((int)neighbor == parent[node]) continue;
        if (parent[neighbor] != -2) return -1;
        parent[neighbor] = (int)node;
        depth[neighbor] = depth[node] + 1;
        preorder[neighbor] = reached + 1;
        order[reached++] = (int)neighbor;
        stack_node[top] = (int)neighbor;
        stack_arc[top] = head[neighbor];
        ++top;
    }
    if (reached != n) return -1;
    if (output_capacity < q || (q != 0 && output == NULL)) return -2;

    for (size_t i = 0; i < n; ++i) inlabel[i] = (uint32_t)preorder[i];
    for (size_t i = n; i > 1; --i) {
        const size_t node = (size_t)order[i - 1];
        const size_t p = (size_t)parent[node];
        if (sv_lowbit(inlabel[p]) < sv_lowbit(inlabel[node])) inlabel[p] = inlabel[node];
    }
    for (size_t i = 0; i < n; ++i) {
        const size_t node = (size_t)order[i];
        if (parent[node] < 0) {
            ascendant[node] = sv_lowbit(inlabel[node]);
            path_head[preorder[node] - 1] = (int)node;
        } else {
            const size_t p = (size_t)parent[node];
            ascendant[node] = ascendant[p] | sv_lowbit(inlabel[node]);
            if (inlabel[node] != inlabel[p]) path_head[preorder[node] - 1] = (int)p;
            else path_head[preorder[node] - 1] = path_head[preorder[p] - 1];
        }
    }

    for (size_t query = 0; query < q; ++query) {
        const size_t u = (size_t)input[query_offset + 2 * query];
        const size_t v = (size_t)input[query_offset + 2 * query + 1];
        const uint32_t lu = sv_lowbit(inlabel[u]), lv = sv_lowbit(inlabel[v]);
        uint32_t mask = sv_highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1u;
        const uint32_t j = sv_lowbit(ascendant[u] & ascendant[v] & ~mask);
        if (j == 0) return -1;

        size_t x = u, y = v;
        if (j != lu) {
            mask = sv_highbit(ascendant[u] & (j - 1u)) - 1u;
            const size_t index = ((preorder[u] & ~(size_t)mask) | ((size_t)mask + 1u)) - 1u;
            x = (size_t)path_head[index];
        }
        if (j != lv) {
            mask = sv_highbit(ascendant[v] & (j - 1u)) - 1u;
            const size_t index = ((preorder[v] & ~(size_t)mask) | ((size_t)mask + 1u)) - 1u;
            y = (size_t)path_head[index];
        }
        const size_t answer = preorder[x] < preorder[y] ? x : y;
        answers[query] = (uint8_t)answer;
    }
    for (size_t query = 0; query < q; ++query) output[query] = answers[query];
    return (int64_t)q;
}
