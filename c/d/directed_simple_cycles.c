/* Enumerate directed simple cycles in source DFS order. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_VERTICES 6
#define MAX_EDGES (MAX_VERTICES * MAX_VERTICES)
#define MAX_OUTPUT_BYTES 2786

int64_t directed_simple_cycles(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_VERTICES ||
        input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t vertices = (size_t)input[0];
    const size_t edges = (size_t)input[1];
    if (length != 2 + 2 * edges) return -1;

    bool adjacency[MAX_VERTICES][MAX_VERTICES] = {{false}};
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t source = input[2 + 2 * edge];
        const int64_t destination = input[3 + 2 * edge];
        if (source < 0 || (uint64_t)source >= vertices || destination < 0 ||
            (uint64_t)destination >= vertices) return -1;
        adjacency[(size_t)source][(size_t)destination] = true;
    }

    uint8_t scratch[MAX_OUTPUT_BYTES];
    size_t output_length = 0;
    for (size_t start = 0; start < vertices; ++start) {
        size_t path[MAX_VERTICES] = {0};
        size_t next_neighbor[MAX_VERTICES] = {0};
        bool visited[MAX_VERTICES] = {false};
        size_t depth = 0;
        path[0] = start;
        visited[start] = true;

        for (;;) {
            const size_t current = path[depth];
            if (next_neighbor[depth] == vertices) {
                visited[current] = false;
                if (depth == 0) break;
                --depth;
                continue;
            }
            const size_t neighbor = next_neighbor[depth]++;
            if (!adjacency[current][neighbor]) continue;
            if (neighbor == start) {
                const size_t path_length = depth + 1;
                for (size_t index = 0; index < path_length; ++index)
                    scratch[output_length++] = (uint8_t)path[index];
                scratch[output_length++] = (uint8_t)start;
                scratch[output_length++] = UINT8_MAX;
            } else if (!visited[neighbor]) {
                ++depth;
                path[depth] = neighbor;
                next_neighbor[depth] = 0;
                visited[neighbor] = true;
            }
        }

        for (size_t vertex = 0; vertex < vertices; ++vertex) {
            adjacency[start][vertex] = false;
            adjacency[vertex][start] = false;
        }
    }
    if (output_length == 0) return 0;
    if (output == NULL || capacity < output_length) return -2;
    memcpy(output, scratch, output_length);
    return (int64_t)output_length;
}
