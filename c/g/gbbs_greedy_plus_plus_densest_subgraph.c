/* Clean-room bounded GBBS GreedyPlusPlus profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>
#include <math.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M + 2 };
static const double INVALID_RESULT = -1.0e300;

double gbbs_greedy_plus_plus_densest_subgraph(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return INVALID_RESULT;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 10 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return INVALID_RESULT;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int64_t load[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return INVALID_RESULT;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return INVALID_RESULT;
        adjacent[u][v] = adjacent[v][u] = 1;
        ++load[u]; ++load[v];
    }
    double best = 0.0;
    for (size_t round = 0; round < 20; ++round) {
        int64_t degree[MAX_N];
        uint8_t alive[MAX_N] = {0};
        size_t order[MAX_N], position[MAX_N];
        for (size_t v = 0; v < n; ++v) { degree[v] = load[v]; alive[v] = 1; }
        size_t used = 0;
        while (used < n) {
            int64_t level = INT64_MAX;
            for (size_t v = 0; v < n; ++v) if (alive[v] && degree[v] < level) level = degree[v];
            size_t shell[MAX_N], count = 0;
            for (size_t v = 0; v < n; ++v) if (alive[v] && degree[v] == level) shell[count++] = v;
            for (size_t i = 0; i < count; ++i) { alive[shell[i]] = 0; order[used++] = shell[i]; }
            for (size_t v = 0; v < n; ++v) if (alive[v]) {
                int64_t removed = 0;
                for (size_t i = 0; i < count; ++i) removed += adjacent[v][shell[i]] != 0;
                const int64_t next = degree[v] - removed;
                degree[v] = next < level ? level : next;
            }
        }
        for (size_t i = 0; i < n; ++i) position[order[i]] = i;
        int64_t density_above[MAX_N] = {0};
        for (size_t v = 0; v < n; ++v) {
            int64_t later = 0;
            for (size_t u = 0; u < n; ++u) if (adjacent[v][u] && position[u] > position[v]) ++later;
            density_above[position[v]] = 2 * later;
            load[v] += later;
        }
        int64_t suffix_sum = 0;
        for (size_t i = n; i-- > 0;) {
            suffix_sum += density_above[i];
            const double score = (double)suffix_sum / (double)(n - i);
            if (score > best) best = score;
        }
    }
    return isfinite(best) ? best : INVALID_RESULT;
}
