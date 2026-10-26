/* Clean-room bounded GBBS Goodrich-Pszona degeneracy-order profile. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 20, MAX_M = 190, MAX_INPUT = 2 + 2 * MAX_M };

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gbbs_goodrich_pszona_degeneracy_order(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M) return -1;
    size_t n = (size_t)n64, m = (size_t)m64;
    if (length != 2 + 2 * m) return -1;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    for (size_t edge = 0; edge < m; ++edge) {
        int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
    }
    if (output == NULL || capacity < 8 * n) return -2;

    size_t degree[MAX_N] = {0};
    uint8_t remaining[MAX_N] = {0};
    int64_t rank[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        remaining[vertex] = 1;
        for (size_t neighbor = 0; neighbor < n; ++neighbor)
            degree[vertex] += adjacent[vertex][neighbor] != 0;
    }
    for (size_t position = 0; position < n; ++position) {
        size_t chosen = n;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if (remaining[vertex] &&
                (chosen == n || degree[vertex] < degree[chosen])) chosen = vertex;
        rank[chosen] = (int64_t)position;
        remaining[chosen] = 0;
        for (size_t neighbor = 0; neighbor < n; ++neighbor)
            if (remaining[neighbor] && adjacent[chosen][neighbor]) --degree[neighbor];
    }
    for (size_t vertex = 0; vertex < n; ++vertex) store_i64_le(output + 8 * vertex, rank[vertex]);
    return (int64_t)(8 * n);
}
