/* Construct a directed Eulerian path with iterative Hierholzer traversal. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGES 256

static void put_i64(uint8_t *output, size_t byte_offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte_offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

int64_t eulerian_path(const int64_t *input, size_t length,
                      uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_VERTICES ||
        input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t vertices = (size_t)input[0];
    const size_t edges = (size_t)input[1];
    if (length != 2 + 2 * edges) return -1;

    uint8_t adjacency[MAX_VERTICES][MAX_EDGES] = {{0}};
    size_t in_degree[MAX_VERTICES] = {0};
    size_t out_degree[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t source = input[2 + 2 * edge];
        const int64_t destination = input[3 + 2 * edge];
        if (source < 0 || (uint64_t)source >= vertices || destination < 0 ||
            (uint64_t)destination >= vertices) return -1;
        adjacency[(size_t)source][out_degree[(size_t)source]++] = (uint8_t)destination;
        ++in_degree[(size_t)destination];
    }
    if (edges == 0) return 0;

    size_t start = 0;
    size_t start_count = 0;
    size_t end_count = 0;
    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        const int64_t difference = (int64_t)out_degree[vertex] - (int64_t)in_degree[vertex];
        if (difference == 1) {
            start = vertex;
            ++start_count;
        } else if (difference == -1) {
            ++end_count;
        } else if (difference != 0) {
            return 0;
        }
    }
    if (!((start_count == 0 && end_count == 0) || (start_count == 1 && end_count == 1))) return 0;
    if (start_count == 0) {
        while (start < vertices && out_degree[start] == 0) ++start;
        if (start == vertices) return 0;
    }

    size_t remaining[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertices; ++vertex) remaining[vertex] = out_degree[vertex];
    size_t stack[MAX_EDGES + 1];
    size_t reverse_path[MAX_EDGES + 1];
    size_t top = 1;
    size_t path_count = 0;
    stack[0] = start;
    while (top != 0) {
        const size_t current = stack[top - 1];
        if (remaining[current] != 0) {
            const size_t adjacency_index = --remaining[current];
            stack[top++] = adjacency[current][adjacency_index];
        } else {
            reverse_path[path_count++] = stack[--top];
        }
    }
    if (path_count != edges + 1) return 0;
    const size_t bytes = path_count * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t index = 0; index < path_count; ++index) {
        put_i64(output, index * 8, (int64_t)reverse_path[path_count - index - 1]);
    }
    return (int64_t)bytes;
}
