#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 32
#define MAX_EDGES 256
#define MAX_INPUT_LENGTH (4 + 2 * MAX_EDGES)
#define MAX_OUTPUT_VALUES (1 + MAX_VERTICES)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t breadth_first_search_shortest_path(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t vertex_value = input[0], edge_value = input[1], start_value = input[2], goal_value = input[3];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES) return -1;
    const int vertices = (int)vertex_value, edges = (int)edge_value;
    if (length != (size_t)(4 + 2 * edges) || start_value < 0 || start_value >= vertices || goal_value < 0 || goal_value >= vertices) return -1;
    int adjacency[MAX_VERTICES * MAX_EDGES], degree[MAX_VERTICES] = {0};
    for (int edge = 0; edge < edges; ++edge) {
        const int64_t from = input[4 + 2 * edge], to = input[5 + 2 * edge];
        if (from < 0 || from >= vertices || to < 0 || to >= vertices) return -1;
        const int source = (int)from;
        adjacency[source * MAX_EDGES + degree[source]++] = (int)to;
    }

    const int start = (int)start_value, goal = (int)goal_value;
    int64_t parent[MAX_VERTICES];
    uint8_t visited[MAX_VERTICES] = {0};
    int queue[MAX_VERTICES], head = 0, tail = 0;
    for (int vertex = 0; vertex < vertices; ++vertex) parent[vertex] = -1;
    visited[start] = 1;
    queue[tail++] = start;
    while (head < tail && !visited[goal]) {
        const int node = queue[head++];
        for (int index = 0; index < degree[node]; ++index) {
            const int neighbor = adjacency[node * MAX_EDGES + index];
            if (visited[neighbor]) continue;
            visited[neighbor] = 1;
            parent[neighbor] = node;
            queue[tail++] = neighbor;
            if (neighbor == goal) break;
        }
    }

    int64_t encoded[MAX_OUTPUT_VALUES];
    size_t path_count = 0;
    if (visited[goal]) {
        int reverse_path[MAX_VERTICES];
        int current = goal;
        while (current >= 0) {
            reverse_path[path_count++] = current;
            if (current == start) break;
            current = (int)parent[current];
        }
        for (size_t index = 0; index < path_count; ++index)
            encoded[1 + index] = reverse_path[path_count - 1 - index];
    }
    encoded[0] = (int64_t)path_count;
    const size_t output_bytes = (path_count + 1) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index <= path_count; ++index) put_i64_le(output, index * 8, encoded[index]);
    return (int64_t)output_bytes;
}
