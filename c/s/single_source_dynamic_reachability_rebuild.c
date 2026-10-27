#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INITIAL_EDGES = 16, MAX_OPERATIONS = 20, MAX_INPUT = 97, MAX_OUTPUT_BYTES = 168 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void rebuild_reachable(int n, int source, const uint8_t adjacency[MAX_N][MAX_N], uint8_t reachable[MAX_N]) {
    int queue[MAX_N];
    int head = 0, tail = 0;
    for (int i = 0; i < n; ++i) reachable[i] = 0;
    reachable[source] = 1;
    queue[tail++] = source;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v) {
            if (adjacency[u][v] && !reachable[v]) {
                reachable[v] = 1;
                queue[tail++] = v;
            }
        }
    }
}

int64_t single_source_dynamic_reachability_rebuild(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0], source_raw = input[1], edge_count_raw = input[2];
    if (n_raw < 2 || n_raw > MAX_N || source_raw < 0 || source_raw >= n_raw ||
            edge_count_raw < 0 || edge_count_raw > MAX_INITIAL_EDGES) return -1;
    const int n = (int)n_raw, source = (int)source_raw, edge_count = (int)edge_count_raw;
    const size_t operation_count_offset = 3u + 2u * (size_t)edge_count;
    if (length <= operation_count_offset) return -1;
    const int64_t operation_count_raw = input[operation_count_offset];
    if (operation_count_raw < 0 || operation_count_raw > MAX_OPERATIONS ||
            length != operation_count_offset + 1u + 3u * (size_t)operation_count_raw) return -1;
    const int operation_count = (int)operation_count_raw;

    uint8_t adjacency[MAX_N][MAX_N] = {{0}};
    size_t cursor = 3;
    for (int i = 0; i < edge_count; ++i) {
        const int64_t u_raw = input[cursor++], v_raw = input[cursor++];
        if (u_raw < 0 || u_raw >= n || v_raw < 0 || v_raw >= n) return -1;
        const int u = (int)u_raw, v = (int)v_raw;
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = 1;
    }
    cursor = operation_count_offset + 1u;
    int op_type[MAX_OPERATIONS], op_u[MAX_OPERATIONS], op_v[MAX_OPERATIONS];
    int query_count = 0;
    for (int i = 0; i < operation_count; ++i) {
        const int64_t kind_raw = input[cursor++], u_raw = input[cursor++], v_raw = input[cursor++];
        if (kind_raw == 0 || kind_raw == 1) {
            if (u_raw < 0 || u_raw >= n || v_raw < 0 || v_raw >= n) return -1;
        } else if (kind_raw == 2) {
            if (u_raw < 0 || u_raw >= n || v_raw != 0) return -1;
            ++query_count;
        } else return -1;
        op_type[i] = (int)kind_raw; op_u[i] = (int)u_raw; op_v[i] = (int)v_raw;
    }

    const size_t output_bytes = 8u * (1u + (size_t)query_count);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t reachable[MAX_N] = {0};
    int64_t answers[MAX_OPERATIONS] = {0};
    int answer_count = 0;
    rebuild_reachable(n, source, adjacency, reachable);
    for (int i = 0; i < operation_count; ++i) {
        if (op_type[i] == 0) {
            adjacency[op_u[i]][op_v[i]] = 1;
            rebuild_reachable(n, source, adjacency, reachable);
        } else if (op_type[i] == 1) {
            adjacency[op_u[i]][op_v[i]] = 0;
            rebuild_reachable(n, source, adjacency, reachable);
        } else {
            answers[answer_count++] = reachable[op_u[i]] ? 1 : 0;
        }
    }
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, 0, answer_count);
    for (int i = 0; i < answer_count; ++i) store_i64_le(staged, 8u * (size_t)(i + 1), answers[i]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
