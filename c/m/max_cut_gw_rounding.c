#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 120
#define MAX_D 4
#define MAX_INPUT 431

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t max_cut_gw_rounding(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], d64 = input[2];
    if (n64 < 2 || n64 > MAX_N || m64 < 0 || m64 > MAX_M || d64 < 1 || d64 > MAX_D ||
        length != 3 + 3 * (size_t)m64 + (size_t)n64 * (size_t)d64 + (size_t)d64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64, d = (size_t)d64;
    int64_t edge_u[MAX_M], edge_v[MAX_M], edge_weight[MAX_M];
    int64_t previous_u = -1, previous_v = -1;
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u = input[3 + 3 * edge], v = input[4 + 3 * edge];
        const int64_t weight = input[5 + 3 * edge];
        if (u < 0 || v <= u || v >= n64 || weight < 1 || weight > 10000 ||
            u < previous_u || (u == previous_u && v <= previous_v)) return -1;
        previous_u = u; previous_v = v;
        edge_u[edge] = u; edge_v[edge] = v; edge_weight[edge] = weight;
    }
    const size_t vector_offset = 3 + 3 * m;
    int64_t vectors[MAX_N][MAX_D] = {{0}}, normal[MAX_D] = {0};
    int64_t common_norm = 0;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        int64_t norm = 0;
        for (size_t axis = 0; axis < d; ++axis) {
            const int64_t coordinate = input[vector_offset + vertex * d + axis];
            if (coordinate < -100 || coordinate > 100) return -1;
            vectors[vertex][axis] = coordinate;
            norm += coordinate * coordinate;
        }
        if (vertex == 0) common_norm = norm;
        else if (norm != common_norm) return -1;
    }
    if (common_norm == 0) return -1;
    int has_normal = 0;
    for (size_t axis = 0; axis < d; ++axis) {
        normal[axis] = input[vector_offset + n * d + axis];
        if (normal[axis] < -100 || normal[axis] > 100) return -1;
        if (normal[axis] != 0) has_normal = 1;
    }
    if (!has_normal) return -1;
    const size_t output_bytes = 8 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t side[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        int64_t projection = 0;
        for (size_t axis = 0; axis < d; ++axis) projection += vectors[vertex][axis] * normal[axis];
        side[vertex] = projection > 0 ? 1 : 0;
    }
    int64_t cut = 0;
    for (size_t edge = 0; edge < m; ++edge)
        if (side[edge_u[edge]] != side[edge_v[edge]]) cut += edge_weight[edge];
    store_i64_le(output, 0, cut);
    for (size_t vertex = 0; vertex < n; ++vertex) store_i64_le(output, 8 * (vertex + 1), side[vertex]);
    return (int64_t)output_bytes;
}
