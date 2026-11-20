#include <stddef.h>
#include <stdint.h>

int64_t undirected_cycle_check_bfs(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > 514 || input[0] < 0 || input[0] > 32 ||
        input[1] < 0 || input[1] > 256) return -1;
    size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;
    uint8_t adjacent[32][32] = {{0}}, visited[32] = {0};
    for (size_t i = 0; i < m; ++i) {
        int64_t a = input[2 + 2 * i], b = input[3 + 2 * i];
        if (a < 0 || b < 0 || a >= (int64_t)n || b >= (int64_t)n || adjacent[a][b]) return -1;
        adjacent[a][b] = adjacent[b][a] = 1;
    }
    size_t queue[32], parent[32];
    for (size_t root = 0; root < n; ++root) {
        if (visited[root]) continue;
        size_t head = 0, tail = 0;
        queue[tail++] = root; parent[root] = n; visited[root] = 1;
        while (head < tail) {
            size_t u = queue[head++];
            for (size_t v = 0; v < n; ++v) if (adjacent[u][v]) {
                if (!visited[v]) { visited[v] = 1; parent[v] = u; queue[tail++] = v; }
                else if (v != parent[u]) return 1;
            }
        }
    }
    return 0;
}
