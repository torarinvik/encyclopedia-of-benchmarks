/* BFS two-coloring for a bounded undirected graph. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 256
#define INVALID_RESULT INT64_C(-1)

int64_t is_graph_bipartite(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 2 + 2 * MAX_EDGES) return INVALID_RESULT;
    const int64_t vertex_count_raw = values[0];
    const int64_t edge_count_raw = values[1];
    if (vertex_count_raw < 0 || vertex_count_raw > MAX_VERTICES ||
        edge_count_raw < 0 || edge_count_raw > MAX_EDGES ||
        length != 2 + 2 * (size_t)edge_count_raw) return INVALID_RESULT;
    const size_t vertex_count = (size_t)vertex_count_raw;
    const size_t edge_count = (size_t)edge_count_raw;

    int head[MAX_VERTICES];
    int to[2 * MAX_EDGES];
    int next[2 * MAX_EDGES];
    int side[MAX_VERTICES];
    int queue[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        head[vertex] = -1;
        side[vertex] = -1;
    }
    int arc_count = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t u_raw = values[2 + 2 * edge];
        const int64_t v_raw = values[3 + 2 * edge];
        if (u_raw < 1 || u_raw > vertex_count_raw || v_raw < 1 || v_raw > vertex_count_raw)
            return INVALID_RESULT;
        const int u = (int)(u_raw - 1);
        const int v = (int)(v_raw - 1);
        to[arc_count] = v; next[arc_count] = head[u]; head[u] = arc_count++;
        to[arc_count] = u; next[arc_count] = head[v]; head[v] = arc_count++;
    }

    int bipartite = 1;
    for (size_t start = 0; start < vertex_count; ++start) {
        if (side[start] != -1) continue;
        size_t queue_head = 0, queue_tail = 0;
        queue[queue_tail++] = (int)start;
        side[start] = 0;
        while (queue_head < queue_tail) {
            const int current = queue[queue_head++];
            for (int arc = head[current]; arc != -1; arc = next[arc]) {
                const int neighbor = to[arc];
                if (side[neighbor] == -1) {
                    side[neighbor] = side[current] ^ 1;
                    queue[queue_tail++] = neighbor;
                } else if (side[neighbor] == side[current]) {
                    bipartite = 0;
                }
            }
        }
    }
    return bipartite;
}
