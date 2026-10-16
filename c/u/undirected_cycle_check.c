/* Detect cycles in a bounded simple undirected graph with iterative DFS. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGES 256

int64_t undirected_cycle_check(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || input[0] < 0 || input[0] > MAX_VERTICES ||
        input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t vertices = (size_t)input[0];
    const size_t edges = (size_t)input[1];
    if (length != 2 + 2 * edges) return -1;

    uint8_t adjacency[MAX_VERTICES * MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t left = input[2 + 2 * edge];
        const int64_t right = input[3 + 2 * edge];
        if (left < 0 || (uint64_t)left >= vertices || right < 0 ||
            (uint64_t)right >= vertices) return -1;
        const size_t left_index = (size_t)left * MAX_VERTICES + (size_t)right;
        const size_t right_index = (size_t)right * MAX_VERTICES + (size_t)left;
        if (adjacency[left_index] != 0) return -1;
        adjacency[left_index] = 1;
        adjacency[right_index] = 1;
    }

    uint8_t visited[MAX_VERTICES] = {0};
    size_t stack_vertex[MAX_VERTICES];
    size_t stack_parent[MAX_VERTICES];
    for (size_t start = 0; start < vertices; ++start) {
        if (visited[start] != 0) continue;
        size_t top = 1;
        stack_vertex[0] = start;
        stack_parent[0] = MAX_VERTICES;
        visited[start] = 1;
        while (top != 0) {
            --top;
            const size_t current = stack_vertex[top];
            const size_t parent = stack_parent[top];
            for (size_t neighbor = 0; neighbor < vertices; ++neighbor) {
                if (adjacency[current * MAX_VERTICES + neighbor] == 0 || neighbor == parent) continue;
                if (visited[neighbor] != 0) return 1;
                visited[neighbor] = 1;
                stack_vertex[top] = neighbor;
                stack_parent[top] = current;
                ++top;
            }
        }
    }
    return 0;
}
