/* Clean-room bounded GBBS BKV12 profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>
#include <math.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M + 2 };
static const double INVALID_RESULT = -1.0e300;

double gbbs_bkv12_densest_subgraph(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return INVALID_RESULT;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return INVALID_RESULT;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int64_t degree[MAX_N] = {0};
    size_t edge_u[MAX_M], edge_v[MAX_M];
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID_RESULT;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return INVALID_RESULT;
        adjacent[u][v] = adjacent[v][u] = 1;
        ++degree[u]; ++degree[v];
        edge_u[edge] = u; edge_v[edge] = v;
    }
    uint8_t alive[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) alive[vertex] = 1;
    size_t remaining = n;
    double best = 0.0;
    while (remaining > 0) {
        int64_t total_degree = 0;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if (alive[vertex]) total_degree += degree[vertex];
        const double density = (double)total_degree / (double)remaining;
        if (density > best) best = density;
        uint8_t removed[MAX_N] = {0};
        size_t removed_count = 0;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (alive[vertex] && 1000 * degree[vertex] * (int64_t)remaining <= 1001 * total_degree) {
                removed[vertex] = 1; ++removed_count;
            }
        }
        if (removed_count == 0) return INVALID_RESULT;
        for (size_t vertex = 0; vertex < n; ++vertex) if (removed[vertex]) alive[vertex] = 0;
        remaining -= removed_count;
        for (size_t edge = 0; edge < m; ++edge) {
            const size_t u = edge_u[edge], v = edge_v[edge];
            if (removed[u] && alive[v]) --degree[v];
            if (removed[v] && alive[u]) --degree[u];
        }
    }
    return isfinite(best) ? best : INVALID_RESULT;
}
