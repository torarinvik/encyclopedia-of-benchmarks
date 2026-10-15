#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 256
#define MAX_QUERIES 1024
#define MAX_ARCS 510
#define LOG_LEVELS 9

int64_t lowest_common_ancestor_binary_lifting(const int64_t *input, size_t length,
                                               uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 4) return -1;
    if (input[0] < 1 || input[0] > MAX_NODES) return -1;
    const size_t node_count = (size_t)input[0];
    if (input[1] < 0 || input[1] >= (int64_t)node_count ||
        input[2] != (int64_t)(node_count - 1) || input[3] < 0 || input[3] > MAX_QUERIES)
        return -1;
    const size_t edge_count = (size_t)input[2], query_count = (size_t)input[3];
    const size_t query_offset = 4 + 2 * edge_count;
    if (length != query_offset + 2 * query_count) return -1;
    const size_t root = (size_t)input[1];

    int head[MAX_NODES], arc_to[MAX_ARCS], arc_next[MAX_ARCS];
    int64_t parent[MAX_NODES];
    size_t depth[MAX_NODES], up[LOG_LEVELS][MAX_NODES], stack[MAX_NODES];
    for (size_t node = 0; node < node_count; ++node) {
        head[node] = -1;
        parent[node] = -2;
    }
    size_t arc_count = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left = input[4 + 2 * edge], right = input[5 + 2 * edge];
        if (left < 0 || left >= (int64_t)node_count || right < 0 || right >= (int64_t)node_count || left == right)
            return -1;
        arc_to[arc_count] = (int)right; arc_next[arc_count] = head[(size_t)left]; head[(size_t)left] = (int)arc_count++;
        arc_to[arc_count] = (int)left; arc_next[arc_count] = head[(size_t)right]; head[(size_t)right] = (int)arc_count++;
    }
    for (size_t query = 0; query < query_count; ++query) {
        if (input[query_offset + 2 * query] < 0 || input[query_offset + 2 * query] >= (int64_t)node_count ||
            input[query_offset + 2 * query + 1] < 0 || input[query_offset + 2 * query + 1] >= (int64_t)node_count)
            return -1;
    }

    size_t top = 0, reached = 0;
    parent[root] = -1;
    up[0][root] = root;
    depth[root] = 0;
    stack[top++] = root;
    while (top != 0) {
        const size_t node = stack[--top];
        ++reached;
        for (int arc = head[node]; arc >= 0; arc = arc_next[arc]) {
            const size_t neighbor = (size_t)arc_to[arc];
            if ((int64_t)neighbor == parent[node]) continue;
            if (parent[neighbor] != -2) return -1;
            parent[neighbor] = (int64_t)node;
            depth[neighbor] = depth[node] + 1;
            up[0][neighbor] = node;
            stack[top++] = neighbor;
        }
    }
    if (reached != node_count) return -1;
    if (output_capacity < query_count || (query_count != 0 && output == NULL)) return -2;

    for (size_t level = 1; level < LOG_LEVELS; ++level)
        for (size_t node = 0; node < node_count; ++node)
            up[level][node] = up[level - 1][up[level - 1][node]];
    for (size_t query = 0; query < query_count; ++query) {
        size_t u = (size_t)input[query_offset + 2 * query];
        size_t v = (size_t)input[query_offset + 2 * query + 1];
        if (depth[u] < depth[v]) { const size_t temp = u; u = v; v = temp; }
        size_t difference = depth[u] - depth[v];
        for (size_t level = 0; level < LOG_LEVELS; ++level) {
            if ((difference & ((size_t)1 << level)) != 0) u = up[level][u];
        }
        if (u != v) {
            for (size_t level = LOG_LEVELS; level-- > 0;) {
                if (up[level][u] != up[level][v]) { u = up[level][u]; v = up[level][v]; }
            }
            u = up[0][u];
        }
        output[query] = (uint8_t)u;
    }
    return (int64_t)query_count;
}
