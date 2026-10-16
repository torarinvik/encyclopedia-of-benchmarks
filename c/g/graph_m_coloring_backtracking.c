/* Bounded first-solution m-coloring with portable scalar recursion. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 12

static bool assign_colors(const int64_t *input, size_t count, size_t max_colors,
                          size_t vertex, int64_t *colors) {
    if (vertex == count) return true;
    for (size_t color = 0; color < max_colors; ++color) {
        bool safe = true;
        for (size_t neighbor = 0; neighbor < count; ++neighbor) {
            if (input[2 + vertex * count + neighbor] == 1 && colors[neighbor] == (int64_t)color) {
                safe = false;
                break;
            }
        }
        if (!safe) continue;
        colors[vertex] = (int64_t)color;
        if (assign_colors(input, count, max_colors, vertex + 1, colors)) return true;
        colors[vertex] = -1;
    }
    return false;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t graph_m_coloring_backtracking(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    int64_t n_value = input[0], colors_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || colors_value < 0 || colors_value > MAX_VERTICES)
        return -1;
    size_t n = (size_t)n_value, max_colors = (size_t)colors_value;
    if (length != 2 + n * n) return -1;
    for (size_t row = 0; row < n; ++row) {
        if (input[2 + row * n + row] != 0) return -1;
        for (size_t column = 0; column < n; ++column) {
            int64_t cell = input[2 + row * n + column];
            if ((cell != 0 && cell != 1) || cell != input[2 + column * n + row]) return -1;
        }
    }
    int64_t colors[MAX_VERTICES];
    for (size_t vertex = 0; vertex < n; ++vertex) colors[vertex] = -1;
    if (!assign_colors(input, n, max_colors, 0, colors)) return 0;
    size_t required = n * 8;
    if (required == 0) return 0;
    if (output == NULL || capacity < required) return -2;
    for (size_t vertex = 0; vertex < n; ++vertex) put_i64(output, vertex * 8, colors[vertex]);
    return (int64_t)required;
}
