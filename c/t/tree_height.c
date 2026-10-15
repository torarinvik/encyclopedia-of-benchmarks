/* Bottom-up DFS heights over the source's undirected adjacency-list tree. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 1023
#define MAX_ARCS (2 * (MAX_NODES - 1))

static int64_t dfs_height(size_t node, size_t count, const int64_t *head,
                          const int64_t *to, const int64_t *next,
                          uint8_t *visited, int64_t *dp, size_t *reached)
{
    visited[node] = 1;
    ++*reached;
    int64_t child_height = 1;
    for (int64_t arc = head[node]; arc >= 0; arc = next[(size_t)arc]) {
        size_t child = (size_t)to[(size_t)arc];
        if (!visited[child]) {
            if (dfs_height(child, count, head, to, next, visited, dp, reached) < 0) return -1;
            if (dp[child] + 1 > child_height) child_height = dp[child] + 1;
        }
    }
    dp[node] = child_height;
    (void)count;
    return child_height;
}

int64_t tree_height(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || values[0] < 1 || values[0] > MAX_NODES) return -1;
    size_t count = (size_t)values[0];
    if (length != 1 + 2 * (count - 1)) return -1;
    int64_t head[MAX_NODES + 1], to[MAX_ARCS], next[MAX_ARCS], dp[MAX_NODES + 1];
    uint8_t visited[MAX_NODES + 1] = {0};
    for (size_t node = 0; node <= count; ++node) head[node] = -1;
    size_t arcs = 0;
    for (size_t edge = 0; edge + 1 < count; ++edge) {
        int64_t a = values[1 + 2 * edge], b = values[2 + 2 * edge];
        if (a < 1 || a > (int64_t)count || b < 1 || b > (int64_t)count || a == b) return -1;
        to[arcs] = b; next[arcs] = head[a]; head[a] = (int64_t)arcs++;
        to[arcs] = a; next[arcs] = head[b]; head[b] = (int64_t)arcs++;
    }
    size_t reached = 0;
    int64_t result = dfs_height(1, count, head, to, next, visited, dp, &reached);
    return result < 0 || reached != count ? -1 : result;
}
