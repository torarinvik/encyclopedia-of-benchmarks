/* Clean-room negative-cycle detection and witness extraction. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 20, MAX_M = 64, MAX_INPUT = 2 + 3 * MAX_M, MAX_OUTPUT = 8 * (MAX_N + 2) };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t negative_cycle_detection(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 3 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    int64_t from[MAX_M], to[MAX_M], weight[MAX_M];
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u = input[2 + 3 * edge];
        const int64_t v = input[3 + 3 * edge];
        const int64_t w = input[4 + 3 * edge];
        if (u < 0 || u >= n64 || v < 0 || v >= n64 || w < -1000 || w > 1000) return -1;
        from[edge] = u; to[edge] = v; weight[edge] = w;
    }

    int64_t distance[MAX_N] = {0};
    int64_t predecessor[MAX_N];
    for (size_t v = 0; v < n; ++v) predecessor[v] = -1;
    int64_t changed_vertex = -1;
    for (size_t pass = 0; pass < n; ++pass) {
        changed_vertex = -1;
        for (size_t edge = 0; edge < m; ++edge) {
            const size_t u = (size_t)from[edge], v = (size_t)to[edge];
            const int64_t candidate = distance[u] + weight[edge];
            if (candidate < distance[v]) {
                distance[v] = candidate;
                predecessor[v] = (int64_t)u;
                changed_vertex = (int64_t)v;
            }
        }
        if (changed_vertex < 0) break;
    }

    int64_t record[MAX_N + 2];
    size_t record_length = 1;
    record[0] = 0;
    if (changed_vertex >= 0) {
        size_t vertex = (size_t)changed_vertex;
        for (size_t step = 0; step < n; ++step) {
            if (predecessor[vertex] < 0) return -1;
            vertex = (size_t)predecessor[vertex];
        }
        const size_t start = vertex;
        size_t cycle[MAX_N], cycle_length = 0;
        do {
            if (cycle_length >= n || predecessor[vertex] < 0) return -1;
            cycle[cycle_length++] = vertex;
            vertex = (size_t)predecessor[vertex];
        } while (vertex != start);
        for (size_t left = 0, right = cycle_length - 1; left < right; ++left, --right) {
            const size_t temporary = cycle[left]; cycle[left] = cycle[right]; cycle[right] = temporary;
        }
        size_t minimum = 0;
        for (size_t i = 1; i < cycle_length; ++i) if (cycle[i] < cycle[minimum]) minimum = i;
        record[0] = 1;
        record[1] = (int64_t)cycle_length;
        for (size_t i = 0; i < cycle_length; ++i)
            record[2 + i] = (int64_t)cycle[(minimum + i) % cycle_length];
        record_length = cycle_length + 2;
    }
    const size_t output_length = 8 * record_length;
    if (output == NULL || capacity < output_length) return -2;
    for (size_t i = 0; i < record_length; ++i) store_i64_le(output, 8 * i, record[i]);
    return (int64_t)output_length;
}
