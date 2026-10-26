/* Clean-room bounded GBBS Charikar profile; see package LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M };
static const double INVALID_RESULT = -1.0e300;

double gbbs_charikar_densest_subgraph(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT + 2) return INVALID_RESULT;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return INVALID_RESULT;
    const int n = (int)n64, m = (int)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int degree[MAX_N] = {0};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * (size_t)edge];
        const int64_t v64 = input[3 + 2 * (size_t)edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID_RESULT;
        const int u = (int)u64, v = (int)v64;
        if (adjacent[u][v]) return INVALID_RESULT;
        adjacent[u][v] = adjacent[v][u] = 1;
        ++degree[u]; ++degree[v];
    }
    uint8_t alive[MAX_N] = {0};
    int order[MAX_N], position[MAX_N];
    for (int v = 0; v < n; ++v) alive[v] = 1;
    int used = 0;
    while (used < n) {
        int level = MAX_M;
        for (int v = 0; v < n; ++v) if (alive[v] && degree[v] < level) level = degree[v];
        for (;;) {
            int shell[MAX_N], shell_count = 0;
            for (int v = 0; v < n; ++v) if (alive[v] && degree[v] == level) shell[shell_count++] = v;
            if (shell_count == 0) break;
            for (int i = 0; i < shell_count; ++i) { alive[shell[i]] = 0; order[used++] = shell[i]; }
            for (int v = 0; v < n; ++v) if (alive[v]) {
                int removed = 0;
                for (int i = 0; i < shell_count; ++i) removed += adjacent[v][shell[i]] != 0;
                degree[v] = degree[v] - removed < level ? level : degree[v] - removed;
            }
        }
    }
    for (int i = 0; i < n; ++i) position[order[i]] = i;
    double best = 0.0;
    for (int start = 0; start < n; ++start) {
        int edges = 0;
        for (int u = 0; u < n; ++u) if (position[u] >= start)
            for (int v = u + 1; v < n; ++v) if (position[v] >= start && adjacent[u][v]) ++edges;
        const double score = (2.0 * (double)edges) / (double)(n - start);
        if (score > best) best = score;
    }
    return isfinite(best) ? best : INVALID_RESULT;
}
