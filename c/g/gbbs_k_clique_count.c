/* Clean-room GBBS fixed-k clique profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 24, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M };

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gbbs_k_clique_count(const int64_t *input, size_t length,
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
        ++degree[u]; ++degree[v];
    }
    if (output == NULL || capacity < 8) return -2;

    /* ORIGINAL ordering directs every edge from the lower ID to the higher.
       The source's k-1 degree filter is safe for k=4 because every clique
       vertex has at least three incident edges. */
    uint8_t directed[MAX_N][MAX_N] = {{0}};
    for (size_t u = 0; u < n; ++u)
        if (degree[u] >= 3)
            for (size_t v = u + 1; v < n; ++v)
                if (degree[v] >= 3 && adjacent[u][v]) directed[u][v] = 1;

    int64_t count = 0;
    for (size_t a = 0; a < n; ++a)
        for (size_t b = a + 1; b < n; ++b) if (directed[a][b])
            for (size_t c = b + 1; c < n; ++c)
                if (directed[a][c] && directed[b][c])
                    for (size_t d = c + 1; d < n; ++d)
                        if (directed[a][d] && directed[b][d] && directed[c][d])
                            ++count;
    store_i64_le(output, count);
    return 8;
}
