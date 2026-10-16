#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_M 256
#define MAX_Q 64
typedef struct { int n, m, q; int adj[MAX_N][MAX_M], degree[MAX_N]; int mode[MAX_Q], start[MAX_Q], dest[MAX_Q]; } Graph;
typedef struct { int length; int nodes[MAX_N]; } Path;

static int dfs(const Graph *g, int at, int dest, int *path, int depth, int *path_length, int visited[MAX_N]) {
    if (visited[at]) return 0;
    visited[at] = 1;
    if (at == dest) { *path_length = depth; return 1; }
    for (int i = 0; i < g->degree[at]; ++i) {
        int next = g->adj[at][i]; path[depth] = next;
        if (dfs(g, next, dest, path, depth + 1, path_length, visited)) return 1;
    }
    return 0;
}
static Path search(const Graph *g, int mode, int start, int dest) {
    Path result = { .length = -1 };
    if (mode == 0) {
        int path[MAX_N] = {0}, visited[MAX_N] = {0};
        int path_length = -1;
        if (dfs(g, start, dest, path, 0, &path_length, visited)) {
            result.length = path_length;
            for (int i = 0; i < path_length; ++i) result.nodes[i] = path[i];
        }
        return result;
    }
    int parent[MAX_N], queue[MAX_N], head = 0, tail = 0;
    for (int i = 0; i < MAX_N; ++i) parent[i] = -1;
    parent[start] = start; queue[tail++] = start;
    while (head < tail) {
        int current = queue[head++];
        if (current == dest) break;
        for (int i = 0; i < g->degree[current]; ++i) {
            int next = g->adj[current][i];
            if (parent[next] == -1) { parent[next] = current; queue[tail++] = next; }
        }
    }
    if (parent[dest] == -1) return result;
    int reverse[MAX_N], count = 0, current = dest;
    while (current != start) { reverse[count++] = current; current = parent[current]; }
    result.length = count;
    for (int i = 0; i < count; ++i) result.nodes[i] = reverse[count - 1 - i];
    return result;
}
static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t graph_swift_directed_paths(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M) return -1;
    size_t m = (size_t)m64, qpos = 2 + 2 * m;
    if (length < qpos + 1) return -1;
    int64_t q64 = input[qpos];
    if (q64 < 1 || q64 > MAX_Q || length != qpos + 1 + 3 * (size_t)q64) return -1;
    Graph g = { .n = (int)n64, .m = (int)m, .q = (int)q64 };
    for (size_t i = 0; i < m; ++i) {
        int64_t from = input[2 + 2 * i], to = input[3 + 2 * i];
        if (from < 0 || from >= n64 || to <= from || to >= n64) return -1;
        g.adj[from][g.degree[from]++] = (int)to;
    }
    for (int i = 0; i < g.q; ++i) {
        size_t p = qpos + 1 + 3 * (size_t)i;
        int64_t mode = input[p], start = input[p + 1], dest = input[p + 2];
        if (mode < 0 || mode > 1 || start < 0 || start >= n64 || dest < 0 || dest >= n64) return -1;
        g.mode[i] = (int)mode; g.start[i] = (int)start; g.dest[i] = (int)dest;
    }
    Path paths[MAX_Q]; size_t words = 0;
    for (int i = 0; i < g.q; ++i) {
        paths[i] = search(&g, g.mode[i], g.start[i], g.dest[i]);
        words += 1 + (paths[i].length > 0 ? (size_t)paths[i].length : 0);
    }
    size_t required = words * 8;
    if (output == NULL || capacity < required) return -2;
    size_t index = 0;
    for (int i = 0; i < g.q; ++i) {
        put_i64(output, index++ * 8, paths[i].length);
        for (int j = 0; j < paths[i].length; ++j) put_i64(output, index++ * 8, paths[i].nodes[j]);
    }
    return (int64_t)required;
}
