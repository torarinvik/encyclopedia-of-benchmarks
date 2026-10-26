/* Clean-room bounded GraphAIBench complete-linkage HAC; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_M = 24, MAX_INPUT = 2 + 3 * MAX_M, MAX_NODES = 2 * MAX_N - 1 };
static const int64_t ROOT_PARENT = INT64_C(4294967295);

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t graphai_hac_complete_linkage(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 3 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    int adjacent[MAX_N][MAX_N] = {{0}};
    int used_weight[33] = {0};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 3 * (size_t)edge];
        const int64_t v64 = input[3 + 3 * (size_t)edge];
        const int64_t w64 = input[4 + 3 * (size_t)edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || w64 < 1 || w64 > 32) return -1;
        const int u = (int)u64, v = (int)v64, w = (int)w64;
        if (adjacent[u][v] != 0 || used_weight[w]) return -1;
        adjacent[u][v] = adjacent[v][u] = w;
        used_weight[w] = 1;
    }
    int reached[MAX_N] = {0}, queue[MAX_N], head = 0, tail = 0;
    reached[0] = 1; queue[tail++] = 0;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v)
            if (adjacent[u][v] != 0 && !reached[v]) { reached[v] = 1; queue[tail++] = v; }
    }
    for (int v = 0; v < n; ++v) if (!reached[v]) return -1;
    const size_t node_count = 2 * (size_t)n - 1;
    const size_t output_bytes = 16 * node_count;
    if (output == NULL || capacity < output_bytes) return -2;

    int active[MAX_N] = {0}, current_id[MAX_N];
    int64_t parent[MAX_NODES];
    int64_t merge_weight[MAX_NODES] = {0};
    for (int node = 0; node < MAX_NODES; ++node) parent[node] = ROOT_PARENT;
    for (int u = 0; u < n; ++u) { active[u] = 1; current_id[u] = u; }
    for (int merge = 0; merge < n - 1; ++merge) {
        int best_u = -1, best_v = -1, best_weight = 0;
        for (int u = 0; u < n; ++u) if (active[u])
            for (int v = u + 1; v < n; ++v)
                if (active[v] && adjacent[u][v] > best_weight) {
                    best_weight = adjacent[u][v]; best_u = u; best_v = v;
                }
        if (best_u < 0) return -1;
        int degree_u = 0, degree_v = 0;
        for (int z = 0; z < n; ++z) {
            degree_u += active[z] && adjacent[best_u][z] != 0;
            degree_v += active[z] && adjacent[best_v][z] != 0;
        }
        const int larger = degree_u < degree_v ? best_v : best_u;
        const int smaller = larger == best_u ? best_v : best_u;
        const int new_id = n + merge;
        parent[current_id[best_u]] = new_id;
        parent[current_id[best_v]] = new_id;
        merge_weight[current_id[best_u]] = best_weight;
        merge_weight[current_id[best_v]] = best_weight;
        int merged_weight[MAX_N] = {0};
        for (int z = 0; z < n; ++z) if (active[z] && z != best_u && z != best_v) {
            const int a = adjacent[best_u][z], b = adjacent[best_v][z];
            if (a != 0 || b != 0) merged_weight[z] = a != 0 && b != 0 ? (a < b ? a : b) : (a != 0 ? a : b);
        }
        for (int z = 0; z < n; ++z) {
            adjacent[best_u][z] = adjacent[z][best_u] = 0;
            adjacent[best_v][z] = adjacent[z][best_v] = 0;
        }
        active[smaller] = 0;
        for (int z = 0; z < n; ++z) if (active[z] && z != larger && merged_weight[z] != 0)
            adjacent[larger][z] = adjacent[z][larger] = merged_weight[z];
        current_id[larger] = new_id;
    }
    for (size_t node = 0; node < node_count; ++node) {
        store_i64_le(output, 16 * node, parent[node]);
        store_i64_le(output, 16 * node + 8, merge_weight[node]);
    }
    return (int64_t)output_bytes;
}
