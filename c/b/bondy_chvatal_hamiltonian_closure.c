#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 28
#define MAX_INPUT_WORDS 59
#define MAX_OUTPUT_WORDS 10

static int degree_of(const uint8_t adjacency[MAX_VERTICES][MAX_VERTICES], int vertex, int n) {
    int degree = 0;
    for (int other = 0; other < n; ++other) degree += adjacency[vertex][other] != 0;
    return degree;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bondy_chvatal_hamiltonian_closure(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int64_t n_word = input[0], m_word = input[1];
    if (n_word < 3 || n_word > MAX_VERTICES || m_word < 0 || m_word > MAX_EDGES) return -1;
    const int n = (int)n_word, m = (int)m_word;
    if (m > n * (n - 1) / 2 || length != (size_t)(2 + 2 * m)) return -1;

    uint8_t adjacency[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u_word = input[2 + 2 * edge], v_word = input[3 + 2 * edge];
        if (u_word < 0 || u_word >= n || v_word < 0 || v_word >= n || u_word == v_word) return -1;
        const int u = (int)u_word, v = (int)v_word;
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
    }

    int added = 0;
    for (;;) {
        int degree[MAX_VERTICES] = {0};
        for (int vertex = 0; vertex < n; ++vertex)
            degree[vertex] = degree_of(adjacency, vertex, n);
        int chosen_u = -1, chosen_v = -1;
        for (int u = 0; u < n && chosen_u < 0; ++u) {
            for (int v = u + 1; v < n; ++v) {
                if (!adjacency[u][v] && degree[u] + degree[v] >= n) {
                    chosen_u = u;
                    chosen_v = v;
                    break;
                }
            }
        }
        if (chosen_u < 0) break;
        adjacency[chosen_u][chosen_v] = adjacency[chosen_v][chosen_u] = 1;
        ++added;
    }

    int64_t staged[MAX_OUTPUT_WORDS] = {0};
    int complete = 1;
    const uint16_t all_vertices = (uint16_t)((1u << n) - 1u);
    for (int u = 0; u < n; ++u) {
        uint16_t row = 0;
        for (int v = 0; v < n; ++v)
            if (adjacency[u][v]) row |= (uint16_t)(1u << v);
        staged[2 + u] = row;
        if (row != (uint16_t)(all_vertices ^ (uint16_t)(1u << u))) complete = 0;
    }
    staged[0] = complete;
    staged[1] = added;

    const size_t output_bytes = (size_t)(2 + n) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t word = 0; word < (size_t)(2 + n); ++word)
        store_i64_le(output, word * 8, staged[word]);
    return (int64_t)output_bytes;
}
