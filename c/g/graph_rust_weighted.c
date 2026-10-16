#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 256

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t graph_rust_weighted(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES
            || length != 2 + 3 * (size_t)m_value) return -1;
    int n = (int)n_value, m = (int)m_value;
    for (int edge = 0; edge < m; ++edge) {
        int64_t u = input[2 + 3 * edge], v = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (u < 0 || u >= n || v < 0 || v >= n || weight < INT32_MIN || weight > INT32_MAX) return -1;
    }
    size_t value_count = 1 + (size_t)n + 4 * (size_t)m;
    size_t required = value_count * 8;
    if (output == NULL || capacity < required) return -2;
    size_t cursor = 0;
    put_i64(output, cursor++ * 8, n);
    for (int vertex = 0; vertex < n; ++vertex) {
        size_t degree = 0;
        for (int edge = 0; edge < m; ++edge) {
            if (input[2 + 3 * edge] == vertex) ++degree;
            if (input[3 + 3 * edge] == vertex) ++degree;
        }
        put_i64(output, cursor++ * 8, (int64_t)degree);
        for (int edge = 0; edge < m; ++edge) {
            int64_t u = input[2 + 3 * edge], v = input[3 + 3 * edge], weight = input[4 + 3 * edge];
            if (u == vertex) {
                put_i64(output, cursor++ * 8, v);
                put_i64(output, cursor++ * 8, weight);
            }
            if (v == vertex) {
                put_i64(output, cursor++ * 8, u);
                put_i64(output, cursor++ * 8, weight);
            }
        }
    }
    return (int64_t)required;
}
