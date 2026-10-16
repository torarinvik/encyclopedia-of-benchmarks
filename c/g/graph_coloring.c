#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_COLORS 4
#define MAX_VALIDATION_LENGTH 11
#define OUTPUT_BYTES 8

static int64_t count_from(const uint8_t *masks, uint8_t *colors,
                          size_t vertex_count, size_t color_count, size_t vertex) {
    if (vertex == vertex_count) return 1;
    int64_t count = 0;
    for (size_t color = 0; color < color_count; ++color) {
        int safe = 1;
        for (size_t prior = 0; prior < vertex; ++prior) {
            if ((masks[vertex] & (uint8_t)(1U << prior)) != 0 && colors[prior] == color) {
                safe = 0;
                break;
            }
        }
        if (safe) {
            colors[vertex] = (uint8_t)color;
            count += count_from(masks, colors, vertex_count, color_count, vertex + 1);
        }
    }
    return count;
}

int64_t graph_coloring(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_VALIDATION_LENGTH) return -1;
    const int64_t n64 = input[0];
    const int64_t m64 = input[1];
    if (n64 < 1 || n64 > MAX_VERTICES || m64 < 1 || m64 > MAX_COLORS) return -1;
    const size_t n = (size_t)n64;
    const size_t m = (size_t)m64;
    if (length != n + 2) return -1;

    uint8_t masks[MAX_VERTICES] = {0};
    uint8_t colors[MAX_VERTICES] = {0};
    const uint64_t mask_limit = UINT64_C(1) << n;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        if (input[2 + vertex] < 0 || (uint64_t)input[2 + vertex] >= mask_limit) return -1;
        masks[vertex] = (uint8_t)input[2 + vertex];
        if ((masks[vertex] & (uint8_t)(1U << vertex)) != 0) return -1;
    }
    for (size_t vertex = 0; vertex < n; ++vertex) {
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            const int edge = (masks[vertex] & (uint8_t)(1U << neighbor)) != 0;
            const int reverse_edge = (masks[neighbor] & (uint8_t)(1U << vertex)) != 0;
            if (edge != reverse_edge) return -1;
        }
    }
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;

    const uint64_t count = (uint64_t)count_from(masks, colors, n, m, 0);
    for (size_t byte = 0; byte < OUTPUT_BYTES; ++byte)
        output[byte] = (uint8_t)(count >> (8 * byte));
    return OUTPUT_BYTES;
}
