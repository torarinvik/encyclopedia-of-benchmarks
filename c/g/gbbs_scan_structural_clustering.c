/* Clean-room bounded GBBS SCAN profile; see package LICENSE.txt. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static void similarity_parts(size_t u, size_t v,
                             const uint8_t adjacent[MAX_N][MAX_N],
                             const size_t degree[MAX_N],
                             uint64_t *numerator, uint64_t *denominator_sq) {
    size_t shared = 0;
    for (size_t w = 0; w < MAX_N; ++w)
        if (adjacent[u][w] && adjacent[v][w]) ++shared;
    *numerator = (uint64_t)(shared + 2);
    *denominator_sq = (uint64_t)(degree[u] + 1) * (uint64_t)(degree[v] + 1);
}

static bool epsilon_similar(uint64_t numerator, uint64_t denominator_sq) {
    return UINT64_C(4) * numerator * numerator >= denominator_sq;
}

int64_t gbbs_scan_structural_clustering(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    size_t degree[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
        ++degree[u];
        ++degree[v];
    }
    if (output == NULL || capacity < 8 * n) return -2;

    bool core[MAX_N] = {false};
    int64_t labels[MAX_N];
    for (size_t u = 0; u < n; ++u) {
        size_t similar_count = 0;
        for (size_t v = 0; v < n; ++v) if (adjacent[u][v]) {
            uint64_t numerator, denominator_sq;
            similarity_parts(u, v, adjacent, degree, &numerator, &denominator_sq);
            if (epsilon_similar(numerator, denominator_sq)) ++similar_count;
        }
        core[u] = similar_count >= 2; /* mu=3, including the vertex itself. */
        labels[u] = -1;
    }

    /* Similar-core connected components, rooted at their minimum vertex ID. */
    for (size_t root = 0; root < n; ++root) {
        if (!core[root] || labels[root] != -1) continue;
        size_t queue[MAX_N], head = 0, tail = 0;
        labels[root] = (int64_t)root;
        queue[tail++] = root;
        while (head < tail) {
            const size_t u = queue[head++];
            for (size_t v = 0; v < n; ++v) {
                if (!core[v] || labels[v] != -1 || !adjacent[u][v]) continue;
                uint64_t numerator, denominator_sq;
                similarity_parts(u, v, adjacent, degree, &numerator, &denominator_sq);
                if (epsilon_similar(numerator, denominator_sq)) {
                    labels[v] = (int64_t)root;
                    queue[tail++] = v;
                }
            }
        }
    }

    /* Deterministic source profile: maximum similarity, then smallest core ID. */
    for (size_t u = 0; u < n; ++u) {
        if (core[u]) continue;
        size_t best_core = MAX_N;
        uint64_t best_num = 0, best_den = 1;
        for (size_t v = 0; v < n; ++v) {
            if (!core[v] || !adjacent[u][v]) continue;
            uint64_t numerator, denominator_sq;
            similarity_parts(u, v, adjacent, degree, &numerator, &denominator_sq);
            if (!epsilon_similar(numerator, denominator_sq)) continue;
            const uint64_t left = numerator * numerator * best_den;
            const uint64_t right = best_num * best_num * denominator_sq;
            if (best_core == MAX_N || left > right ||
                (left == right && v < best_core)) {
                best_core = v;
                best_num = numerator;
                best_den = denominator_sq;
            }
        }
        if (best_core != MAX_N) labels[u] = labels[best_core];
    }
    for (size_t v = 0; v < n; ++v) store_i64_le(output, 8 * v, labels[v]);
    return (int64_t)(8 * n);
}
