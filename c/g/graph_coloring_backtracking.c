/* Port of Go Graph.ColorUsingBacktracking for simple undirected graphs. */
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define MAX_VERTICES 64
#define MAX_EDGES 2016
#define MAX_OUTPUT_VALUES (MAX_VERTICES + 2)

static bool color_vertex(size_t vertex, size_t count, const bool *adjacency, int64_t *colors) {
    if (vertex == count) return true;
    for (int64_t color = 1; color <= (int64_t)count; ++color) {
        bool safe = true;
        for (size_t neighbor = 0; neighbor < count; ++neighbor) {
            if (adjacency[vertex * MAX_VERTICES + neighbor] && colors[neighbor] == color) {
                safe = false;
                break;
            }
        }
        if (!safe) continue;
        colors[vertex] = color;
        if (color_vertex(vertex + 1, count, adjacency, colors)) return true;
        colors[vertex] = 0;
    }
    return false;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t graph_coloring_backtracking(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES ||
        length != 2 + 2 * (size_t)m_value) return -1;
    size_t n = (size_t)n_value, m = (size_t)m_value;
    bool adjacency[MAX_VERTICES * MAX_VERTICES] = {false};
    for (size_t edge = 0; edge < m; ++edge) {
        int64_t u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value)
            return -1;
        size_t u = (size_t)u_value, v = (size_t)v_value;
        adjacency[u * MAX_VERTICES + v] = true;
        adjacency[v * MAX_VERTICES + u] = true;
    }
    int64_t colors[MAX_VERTICES] = {0};
    if (!color_vertex(0, n, adjacency, colors)) return -1;
    int64_t colors_used = 0;
    for (size_t vertex = 0; vertex < n; ++vertex)
        if (colors[vertex] > colors_used) colors_used = colors[vertex];
    int64_t packed[MAX_OUTPUT_VALUES];
    packed[0] = n_value;
    for (size_t vertex = 0; vertex < n; ++vertex) packed[vertex + 1] = colors[vertex];
    packed[n + 1] = colors_used;
    size_t used = n + 2, required = used * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < used; ++index) put_i64(output, index * 8, packed[index]);
    return (int64_t)required;
}
