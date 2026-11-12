#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 8, MAX_EDGES = 12, MAX_INPUT_LENGTH = 26, MAX_OUTPUT_BYTES = 96 };

int64_t counting_c4(const int64_t *values, size_t length,
                    uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = values[0];
    const int64_t m_value = values[1];
    if (n_value < 2 || n_value > MAX_VERTICES || m_value < 1 || m_value > MAX_EDGES) return -1;
    const size_t n = (size_t)n_value;
    const size_t edge_count = (size_t)m_value;
    if (length != 2 + 2 * edge_count) return -1;

    int64_t multiplicity[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t u_value = values[2 + 2 * edge];
        const int64_t v_value = values[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value)
            return -1;
        const size_t u = (size_t)u_value;
        const size_t v = (size_t)v_value;
        ++multiplicity[u][v];
        ++multiplicity[v][u];
    }

    uint64_t answers[MAX_EDGES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const size_t u = (size_t)values[2 + 2 * edge];
        const size_t v = (size_t)values[3 + 2 * edge];
        for (size_t a = 0; a < n; ++a) {
            if (a == u || a == v) continue;
            for (size_t b = 0; b < n; ++b) {
                if (b == u || b == v || b == a) continue;
                answers[edge] += (uint64_t)(multiplicity[u][a] * multiplicity[a][b] * multiplicity[b][v]);
            }
        }
    }

    const size_t bytes = 8 * edge_count;
    if (output == NULL || output_capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge)
        for (size_t byte = 0; byte < 8; ++byte)
            staged[8 * edge + byte] = (uint8_t)(answers[edge] >> (8 * byte));
    for (size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)bytes;
}
