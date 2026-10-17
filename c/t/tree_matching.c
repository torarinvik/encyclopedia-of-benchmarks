/* Two-state maximum-weight matching DP on the supplied undirected tree. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 64
#define MAX_INPUT_VALUES (2 + 3 * (MAX_NODES - 1))

static void matching_dp(size_t node, int parent, size_t count,
                        const uint8_t adjacent[MAX_NODES][MAX_NODES],
                        const int64_t weight[MAX_NODES][MAX_NODES],
                        uint8_t visited[MAX_NODES], int parent_of[MAX_NODES],
                        int64_t without_edge[MAX_NODES],
                        int64_t with_edge[MAX_NODES], size_t *reached)
{
    visited[node] = 1;
    parent_of[node] = parent;
    ++*reached;
    int64_t base = 0;
    for (size_t child = 0; child < count; ++child) {
        if (adjacent[node][child] && (int)child != parent && !visited[child]) {
            matching_dp(child, (int)node, count, adjacent, weight, visited,
                        parent_of, without_edge, with_edge, reached);
            base += without_edge[child] > with_edge[child]
                        ? without_edge[child] : with_edge[child];
        }
    }
    without_edge[node] = base;
    with_edge[node] = 0;
    for (size_t child = 0; child < count; ++child) {
        if (parent_of[child] == (int)node) {
            int64_t child_best = without_edge[child] > with_edge[child]
                                     ? without_edge[child] : with_edge[child];
            int64_t candidate = base - child_best + without_edge[child] + weight[node][child];
            if (candidate > with_edge[node]) with_edge[node] = candidate;
        }
    }
}

int64_t tree_matching(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_VALUES || values[0] < 1 || values[0] > MAX_NODES) return -1;
    size_t count = (size_t)values[0];
    if (length != 2 + 3 * (count - 1) || values[1] < 0 || values[1] >= (int64_t)count) return -1;
    uint8_t adjacent[MAX_NODES][MAX_NODES] = {{0}};
    int64_t weight[MAX_NODES][MAX_NODES] = {{0}};
    for (size_t edge = 0; edge < count - 1; ++edge) {
        int64_t a_value = values[2 + 3 * edge], b_value = values[3 + 3 * edge];
        int64_t w = values[4 + 3 * edge];
        if (a_value < 0 || b_value < 0 || a_value >= (int64_t)count ||
            b_value >= (int64_t)count || a_value == b_value || w < 0 || w > 1000) return -1;
        size_t a = (size_t)a_value, b = (size_t)b_value;
        if (adjacent[a][b]) return -1;
        adjacent[a][b] = adjacent[b][a] = 1;
        weight[a][b] = weight[b][a] = w;
    }
    uint8_t visited[MAX_NODES] = {0};
    int parent_of[MAX_NODES];
    int64_t without_edge[MAX_NODES] = {0}, with_edge[MAX_NODES] = {0};
    for (size_t node = 0; node < count; ++node) parent_of[node] = -2;
    size_t reached = 0;
    size_t root = (size_t)values[1];
    matching_dp(root, -1, count, adjacent, weight, visited,
                parent_of, without_edge, with_edge, &reached);
    if (reached != count) return -1;
    return without_edge[root] > with_edge[root] ? without_edge[root] : with_edge[root];
}
