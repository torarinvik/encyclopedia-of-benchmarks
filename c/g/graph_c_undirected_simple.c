/* Normalize the simple undirected C graph ADT to a row-major adjacency matrix. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGES 2047

static void put_i64(uint8_t *output, size_t slot, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[slot * 8 + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t graph_c_undirected_simple(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t vertices = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    uint8_t adjacency[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left_value = input[2 + 2 * edge];
        const int64_t right_value = input[3 + 2 * edge];
        if (left_value < 0 || right_value < 0 || (uint64_t)left_value >= vertices || (uint64_t)right_value >= vertices) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        adjacency[left][right] = 1;
        adjacency[right][left] = 1;
    }
    const size_t count = vertices * vertices;
    if (output == NULL || capacity < count * 8) return -2;
    for (size_t row = 0; row < vertices; ++row)
        for (size_t column = 0; column < vertices; ++column)
            put_i64(output, row * vertices + column, adjacency[row][column]);
    return (int64_t)(count * 8);
}
