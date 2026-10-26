module graphai_hac_complete_linkage;

const long MAX_N = 8;
const long MAX_M = 24;
const long MAX_INPUT = 74;
const long MAX_NODES = 15;
const long ROOT_PARENT = 4294967295;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

// Clean-room bounded GraphAIBench complete-linkage HAC; see package LICENSE.txt.
long graphai_hac_complete_linkage(long* input, usz length, char* output, usz capacity)
        @export("graphai_hac_complete_linkage") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 3 * (usz)m64) return -1;
    usz n = (usz)n64, m = (usz)m64;
    long[MAX_N * MAX_N] adjacent = zeroed;
    bool[33] used_weight = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u64 = input[2 + 3 * edge], v64 = input[3 + 3 * edge], w64 = input[4 + 3 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || w64 < 1 || w64 > 32) return -1;
        usz u = (usz)u64, v = (usz)v64, w = (usz)w64;
        if (adjacent[u * MAX_N + v] != 0 || used_weight[w]) return -1;
        adjacent[u * MAX_N + v] = (long)w;
        adjacent[v * MAX_N + u] = (long)w;
        used_weight[w] = true;
    }
    bool[MAX_N] reached = zeroed;
    usz[MAX_N] queue = zeroed;
    usz head = 0, tail = 1;
    reached[0] = true; queue[0] = 0;
    while (head < tail) {
        usz u = queue[head]; head += 1;
        for (usz v = 0; v < n; v += 1)
            if (adjacent[u * MAX_N + v] != 0 && !reached[v]) {
                reached[v] = true; queue[tail] = v; tail += 1;
            }
    }
    for (usz v = 0; v < n; v += 1) if (!reached[v]) return -1;
    usz node_count = 2 * n - 1, output_bytes = 16 * node_count;
    if (output == null || capacity < output_bytes) return -2;

    bool[MAX_N] active = zeroed;
    usz[MAX_N] current_id = zeroed;
    long[MAX_NODES] parent;
    long[MAX_NODES] merge_weight = zeroed;
    for (usz node = 0; node < MAX_NODES; node += 1) parent[node] = ROOT_PARENT;
    for (usz u = 0; u < n; u += 1) { active[u] = true; current_id[u] = u; }
    for (usz merge = 0; merge < n - 1; merge += 1) {
        long best_weight = 0;
        usz best_u = n, best_v = n;
        for (usz u = 0; u < n; u += 1) if (active[u])
            for (usz v = u + 1; v < n; v += 1)
                if (active[v] && adjacent[u * MAX_N + v] > best_weight) {
                    best_weight = adjacent[u * MAX_N + v]; best_u = u; best_v = v;
                }
        if (best_u == n) return -1;
        usz degree_u = 0, degree_v = 0;
        for (usz z = 0; z < n; z += 1) {
            if (active[z] && adjacent[best_u * MAX_N + z] != 0) degree_u += 1;
            if (active[z] && adjacent[best_v * MAX_N + z] != 0) degree_v += 1;
        }
        usz larger = degree_u < degree_v ? best_v : best_u;
        usz smaller = larger == best_u ? best_v : best_u;
        usz new_id = n + merge;
        parent[current_id[best_u]] = (long)new_id;
        parent[current_id[best_v]] = (long)new_id;
        merge_weight[current_id[best_u]] = best_weight;
        merge_weight[current_id[best_v]] = best_weight;
        long[MAX_N] merged_weight = zeroed;
        for (usz z = 0; z < n; z += 1) if (active[z] && z != best_u && z != best_v) {
            long a = adjacent[best_u * MAX_N + z], b = adjacent[best_v * MAX_N + z];
            if (a != 0 || b != 0) merged_weight[z] = a != 0 && b != 0 ? (a < b ? a : b) : (a != 0 ? a : b);
        }
        for (usz z = 0; z < n; z += 1) {
            adjacent[best_u * MAX_N + z] = adjacent[z * MAX_N + best_u] = 0;
            adjacent[best_v * MAX_N + z] = adjacent[z * MAX_N + best_v] = 0;
        }
        active[smaller] = false;
        for (usz z = 0; z < n; z += 1)
            if (active[z] && z != larger && merged_weight[z] != 0) {
                adjacent[larger * MAX_N + z] = merged_weight[z];
                adjacent[z * MAX_N + larger] = merged_weight[z];
            }
        current_id[larger] = new_id;
    }
    for (usz node = 0; node < node_count; node += 1) {
        store_i64_le(output, 16 * node, parent[node]);
        store_i64_le(output, 16 * node + 8, merge_weight[node]);
    }
    return (long)output_bytes;
}
