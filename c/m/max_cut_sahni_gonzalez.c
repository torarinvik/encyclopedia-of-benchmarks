#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 120
#define MAX_INPUT (2 + 3 * MAX_M)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t max_cut_sahni_gonzalez(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != (size_t)(2 + 3 * m64)) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    int64_t weights[MAX_N][MAX_N] = {{0}};
    uint8_t seen[MAX_N][MAX_N] = {{0}};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 3 * edge], v64 = input[3 + 3 * edge];
        const int64_t weight = input[4 + 3 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || weight < 0 || weight > 10000) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (seen[u][v]) return -1;
        seen[u][v] = 1;
        weights[u][v] = weight;
        weights[v][u] = weight;
    }
    const size_t output_bytes = 8 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t side[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        int64_t put_zero = 0, put_one = 0;
        for (size_t prior = 0; prior < vertex; ++prior) {
            if (side[prior] == 1) put_zero += weights[prior][vertex];
            else put_one += weights[prior][vertex];
        }
        side[vertex] = put_one > put_zero ? 1 : 0;
    }
    int64_t cut = 0;
    for (size_t u = 0; u < n; ++u)
        for (size_t v = u + 1; v < n; ++v)
            if (side[u] != side[v]) cut += weights[u][v];
    store_i64_le(output, 0, cut);
    for (size_t vertex = 0; vertex < n; ++vertex) store_i64_le(output, 8 * (vertex + 1), side[vertex]);
    return (int64_t)output_bytes;
}
