#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_M = 66, MAX_K = 6, MAX_TRIALS = 8, MAX_INPUT = 232, MAX_OUTPUT = 64 };
static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[at + b] = (uint8_t)(bits & 255u); bits >>= 8; }
}
static int path_less(const int8_t *left, const int8_t *right, int length) {
    for (int i = 0; i < length; ++i) {
        if (left[i] != right[i]) return left[i] < right[i];
    }
    return 0;
}

int64_t color_coding_random_k_path(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M
        || input[2] < 1 || input[2] > MAX_K || input[2] > input[0]
        || input[3] < 1 || input[3] > MAX_TRIALS) return -1;
    int n = (int)input[0], m = (int)input[1], k = (int)input[2], trials = (int)input[3];
    size_t edge_start = 4, color_start = edge_start + 2u * (size_t)m;
    if (length != color_start + (size_t)trials * (size_t)n) return -1;
    uint16_t adjacency[MAX_N] = {0};
    for (int e = 0; e < m; ++e) {
        int64_t av = input[edge_start + 2u * (size_t)e], bv = input[edge_start + 2u * (size_t)e + 1];
        if (av < 0 || bv < 0 || av >= n || bv >= n || av == bv) return -1;
        int a = (int)av, b = (int)bv;
        if (adjacency[a] & (1u << b)) return -1;
        adjacency[a] |= (uint16_t)(1u << b); adjacency[b] |= (uint16_t)(1u << a);
    }
    for (int t = 0; t < trials; ++t)
        for (int v = 0; v < n; ++v) {
            int64_t color = input[color_start + (size_t)t * (size_t)n + (size_t)v];
            if (color < 0 || color >= k) return -1;
        }
    int full = (1 << k) - 1;
    for (int trial = 0; trial < trials; ++trial) {
        int colors[MAX_N];
        for (int v = 0; v < n; ++v) colors[v] = (int)input[color_start + (size_t)trial * (size_t)n + (size_t)v];
        uint8_t reachable[1 << MAX_K][MAX_N] = {{0}};
        int8_t paths[1 << MAX_K][MAX_N][MAX_K];
        for (int mask = 0; mask <= full; ++mask) for (int v = 0; v < n; ++v)
            for (int j = 0; j < k; ++j) paths[mask][v][j] = -1;
        for (int v = 0; v < n; ++v) {
            int mask = 1 << colors[v]; reachable[mask][v] = 1; paths[mask][v][0] = (int8_t)v;
        }
        for (int mask = 1; mask <= full; ++mask) {
            int path_length = 0;
            for (int bits = mask; bits != 0; bits &= bits - 1) ++path_length;
            for (int v = 0; v < n; ++v) if (reachable[mask][v] && mask != full) {
                for (int u = 0; u < n; ++u) {
                    int color_bit = 1 << colors[u];
                    if (!(adjacency[v] & (1u << u)) || (mask & color_bit)) continue;
                    int next_mask = mask | color_bit;
                    int8_t candidate[MAX_K];
                    for (int j = 0; j < path_length; ++j) candidate[j] = paths[mask][v][j];
                    candidate[path_length] = (int8_t)u;
                    if (!reachable[next_mask][u] || path_less(candidate, paths[next_mask][u], path_length + 1)) {
                        reachable[next_mask][u] = 1;
                        for (int j = 0; j <= path_length; ++j) paths[next_mask][u][j] = candidate[j];
                    }
                }
            }
        }
        int best = -1;
        for (int v = 0; v < n; ++v)
            if (reachable[full][v] && (best < 0 || path_less(paths[full][v], paths[full][best], k))) best = v;
        if (best >= 0) {
            size_t bytes = 8u * (size_t)(k + 2);
            if (output == NULL || capacity < bytes) return -2;
            uint8_t staged[MAX_OUTPUT] = {0};
            put_i64(staged, 0, 1); put_i64(staged, 8, trial + 1);
            for (int j = 0; j < k; ++j) put_i64(staged, 8u * (size_t)(j + 2), paths[full][best][j]);
            for (size_t j = 0; j < bytes; ++j) output[j] = staged[j];
            return (int64_t)bytes;
        }
    }
    if (output == NULL || capacity < 16) return -2;
    uint8_t staged[16] = {0};
    put_i64(staged, 0, 0); put_i64(staged, 8, 0);
    for (size_t j = 0; j < 16; ++j) output[j] = staged[j];
    return 16;
}
