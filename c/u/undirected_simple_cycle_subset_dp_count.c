/* Clean-room all-length simple-cycle subset DP; see package RIGHTS.md. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 14, MAX_M = 91, MAX_INPUT = 185, MAX_STATES = 1 << MAX_N };

int64_t undirected_simple_cycle_subset_dp_count(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0];
    const int64_t m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 ||
        m64 > n64 * (n64 - 1) / 2) return -1;
    const size_t n = (size_t)n64;
    const size_t m = (size_t)m64;
    if (length != 2 + 2 * m) return -1;

    uint8_t adjacency[MAX_N][MAX_N] = {{0}};
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
        adjacency[u][v] = adjacency[v][u] = 1;
        neighbors[u][degree[u]++] = v;
        neighbors[v][degree[v]++] = u;
    }

    int64_t dp[MAX_STATES][MAX_N] = {{0}};
    const size_t state_count = (size_t)1 << n;
    for (size_t start = 0; start < n; ++start) dp[(size_t)1 << start][start] = 1;
    int64_t oriented_cycles = 0;
    for (size_t mask = 1; mask < state_count; ++mask) {
        size_t start = 0;
        while ((mask & ((size_t)1 << start)) == 0) ++start;
        size_t cardinality = 0;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if (mask & ((size_t)1 << vertex)) ++cardinality;
        for (size_t endpoint = 0; endpoint < n; ++endpoint) {
            if ((mask & ((size_t)1 << endpoint)) == 0) continue;
            const int64_t ways = dp[mask][endpoint];
            if (ways == 0) continue;
            if (cardinality >= 3 && adjacency[endpoint][start]) oriented_cycles += ways;
            for (size_t i = 0; i < degree[endpoint]; ++i) {
                const size_t next = neighbors[endpoint][i];
                if (next > start && (mask & ((size_t)1 << next)) == 0)
                    dp[mask | ((size_t)1 << next)][next] += ways;
            }
        }
    }
    return oriented_cycles / 2;
}
