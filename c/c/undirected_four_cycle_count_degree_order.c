/* Clean-room degree-oriented simple C4 counter; see package RIGHTS.md. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 131 };

int64_t undirected_four_cycle_count_degree_order(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0];
    const int64_t m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M) return -1;
    const size_t n = (size_t)n64;
    const size_t m = (size_t)m64;
    if (length != 2 + 2 * m) return -1;

    size_t neighbors[MAX_N][MAX_N] = {{0}};
    size_t degree[MAX_N] = {0};
    int64_t previous_u = -1;
    int64_t previous_v = -1;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge];
        const int64_t v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n64 || v64 < 0 || v64 >= n64 || u64 >= v64) return -1;
        if (edge != 0 && (u64 < previous_u || (u64 == previous_u && v64 <= previous_v))) return -1;
        previous_u = u64;
        previous_v = v64;
        const size_t u = (size_t)u64;
        const size_t v = (size_t)v64;
        neighbors[u][degree[u]++] = v;
        neighbors[v][degree[v]++] = u;
    }

    size_t order[MAX_N];
    size_t rank[MAX_N];
    for (size_t i = 0; i < n; ++i) order[i] = i;
    for (size_t i = 1; i < n; ++i) {
        const size_t key = order[i];
        size_t j = i;
        while (j > 0) {
            const size_t prior = order[j - 1];
            if (degree[prior] < degree[key] ||
                (degree[prior] == degree[key] && prior < key)) break;
            order[j] = prior;
            --j;
        }
        order[j] = key;
    }
    for (size_t i = 0; i < n; ++i) rank[order[i]] = i;

    int64_t count[MAX_N] = {0};
    int64_t total = 0;
    for (size_t position = 0; position < n; ++position) {
        const size_t pivot = order[position];
        for (size_t bi = 0; bi < degree[pivot]; ++bi) {
            const size_t middle = neighbors[pivot][bi];
            if (rank[middle] >= position) continue;
            for (size_t ci = 0; ci < degree[middle]; ++ci) {
                const size_t opposite = neighbors[middle][ci];
                if (rank[opposite] < position) {
                    total += count[opposite];
                    ++count[opposite];
                }
            }
        }
        for (size_t vertex = 0; vertex < n; ++vertex) count[vertex] = 0;
    }
    return total;
}
