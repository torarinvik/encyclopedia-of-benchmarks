/* Clean-room bounded GBBS CoSimRank pair profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 24, MAX_ITERS = 4, MAX_INPUT = 5 + 2 * MAX_M };

static void store_scaled_binary64(uint8_t *output, uint32_t numerator) {
    uint64_t bits = 0;
    if (numerator != 0) {
        unsigned high = 0;
        while ((numerator >> (high + 1)) != 0) ++high;
        const uint64_t exponent = (uint64_t)(1003 + high);
        const uint64_t significand = (uint64_t)numerator << (52 - high);
        bits = (exponent << 52) | (significand & ((UINT64_C(1) << 52) - 1));
    }
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gbbs_cosimrank_pair_similarity(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    const int64_t source_u64 = input[2], source_v64 = input[3], iterations64 = input[4];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        source_u64 < 0 || source_u64 >= n64 || source_v64 < 0 || source_v64 >= n64 ||
        iterations64 < 1 || iterations64 > MAX_ITERS || length != 5 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    const size_t source_u = (size_t)source_u64, source_v = (size_t)source_v64;
    size_t edge_from[MAX_M], edge_to[MAX_M], degree[MAX_N] = {0};
    uint8_t seen[MAX_N][MAX_N] = {{0}};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t from64 = input[5 + 2 * edge], to64 = input[6 + 2 * edge];
        if (from64 < 0 || from64 >= n64 || to64 < 0 || to64 >= n64 || from64 == to64) return -1;
        const size_t from = (size_t)from64, to = (size_t)to64;
        if (seen[from][to]) return -1;
        seen[from][to] = 1;
        edge_from[edge] = from; edge_to[edge] = to; ++degree[from];
    }
    for (size_t vertex = 0; vertex < n; ++vertex)
        if (degree[vertex] != 0 && degree[vertex] != 1 && degree[vertex] != 2 && degree[vertex] != 4) return -1;
    if (output == NULL || capacity < 8) return -2;

    /* Probability vectors use a common 2^8 scale; all admitted transitions divide exactly. */
    uint32_t current_u[MAX_N] = {0}, current_v[MAX_N] = {0};
    uint32_t next_u[MAX_N] = {0}, next_v[MAX_N] = {0};
    current_u[source_u] = 256; current_v[source_v] = 256;
    uint32_t numerator = source_u == source_v ? (UINT32_C(1) << 20) : 0;
    for (size_t step = 0; step < (size_t)iterations64; ++step) {
        for (size_t edge = 0; edge < m; ++edge) {
            const size_t from = edge_from[edge], to = edge_to[edge];
            next_u[to] += current_u[from] / (uint32_t)degree[from];
            next_v[to] += current_v[from] / (uint32_t)degree[from];
        }
        uint32_t dot = 0;
        for (size_t vertex = 0; vertex < n; ++vertex) dot += next_u[vertex] * next_v[vertex];
        numerator += dot << (3 - step);
        for (size_t vertex = 0; vertex < n; ++vertex) {
            current_u[vertex] = next_u[vertex]; current_v[vertex] = next_v[vertex];
            next_u[vertex] = 0; next_v[vertex] = 0;
        }
    }
    store_scaled_binary64(output, numerator);
    return 8;
}
