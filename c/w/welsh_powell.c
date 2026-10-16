#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGE_PAIRS 512
#define MAX_VALIDATION_LENGTH (2 + 2 * MAX_EDGE_PAIRS + 1)
#define OUTPUT_BYTES_PER_VERTEX 8

static uint64_t vertex_bit(size_t vertex) {
    return UINT64_C(1) << vertex;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < OUTPUT_BYTES_PER_VERTEX; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t welsh_powell(const int64_t *input, size_t length,
                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_VALIDATION_LENGTH) return -1;
    const int64_t n64 = input[0];
    const int64_t edge_count64 = input[1];
    if (n64 < 0 || n64 > MAX_VERTICES || edge_count64 < 0 || edge_count64 > MAX_EDGE_PAIRS) return -1;
    const size_t n = (size_t)n64;
    const size_t edge_count = (size_t)edge_count64;
    if (length != 2 + 2 * edge_count) return -1;

    uint64_t adjacency[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left64 = input[2 + 2 * edge];
        const int64_t right64 = input[3 + 2 * edge];
        if (left64 < 0 || left64 >= n64 || right64 < 0 || right64 >= n64 || left64 == right64) return -1;
        const size_t left = (size_t)left64;
        const size_t right = (size_t)right64;
        adjacency[left] |= vertex_bit(right);
        adjacency[right] |= vertex_bit(left);
    }

    const size_t output_bytes = n * OUTPUT_BYTES_PER_VERTEX;
    if (output == NULL || capacity < output_bytes) return -2;

    size_t degrees[MAX_VERTICES] = {0};
    size_t order[MAX_VERTICES] = {0};
    int64_t colors[MAX_VERTICES];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        colors[vertex] = -1;
        order[vertex] = vertex;
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            if ((adjacency[vertex] & vertex_bit(neighbor)) != 0) ++degrees[vertex];
        }
    }

    /* Stable descending degree order keeps equal-degree vertices by index. */
    for (size_t index = 1; index < n; ++index) {
        const size_t key = order[index];
        size_t position = index;
        while (position > 0 && degrees[order[position - 1]] < degrees[key]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }

    uint64_t colored_vertices = 0;
    for (size_t index = 0; index < n; ++index) {
        const size_t vertex = order[index];
        if (colors[vertex] >= 0) continue;

        uint64_t used_colors = 0;
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            if ((adjacency[vertex] & vertex_bit(neighbor)) != 0 && colors[neighbor] >= 0) {
                used_colors |= vertex_bit((size_t)colors[neighbor]);
            }
        }
        size_t color = 0;
        while ((used_colors & vertex_bit(color)) != 0) ++color;
        colors[vertex] = (int64_t)color;
        colored_vertices |= vertex_bit(vertex);

        for (size_t other_index = 0; other_index < n; ++other_index) {
            const size_t other = order[other_index];
            if (colors[other] < 0 && (adjacency[other] & colored_vertices) == 0) {
                colors[other] = (int64_t)color;
                colored_vertices |= vertex_bit(other);
            }
        }
    }

    for (size_t vertex = 0; vertex < n; ++vertex) {
        put_i64_le(output, vertex * OUTPUT_BYTES_PER_VERTEX, colors[vertex]);
    }
    return (int64_t)output_bytes;
}
