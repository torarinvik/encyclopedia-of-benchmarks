/* One-target directed BFS distance with vertices mapped to single characters. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 26
#define MAX_EDGES 256

int64_t breadth_first_search_shortest_path_distance(const int64_t *input, size_t length) {
    if (input == NULL || length < 4) return -1;
    const int64_t vertices_value = input[0];
    const int64_t edges_value = input[1];
    const int64_t source_value = input[2];
    const int64_t target_value = input[3];
    if (vertices_value < 1 || vertices_value > MAX_VERTICES || edges_value < 0 || edges_value > MAX_EDGES)
        return -1;
    const size_t vertices = (size_t)vertices_value;
    const size_t edges = (size_t)edges_value;
    if (source_value < 0 || source_value >= vertices_value || target_value < 0 || target_value >= vertices_value ||
        length != 4 + 2 * edges) return -1;

    uint8_t adjacent[MAX_VERTICES * MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t from = input[4 + 2 * edge];
        const int64_t to = input[5 + 2 * edge];
        if (from < 0 || from >= vertices_value || to < 0 || to >= vertices_value) return -1;
        adjacent[(size_t)from * vertices + (size_t)to] = 1;
    }

    const size_t source = (size_t)source_value, target = (size_t)target_value;
    int64_t distance[MAX_VERTICES];
    size_t queue[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertices; ++vertex) distance[vertex] = -1;
    size_t head = 0, tail = 0;
    distance[source] = 0;
    queue[tail++] = source;
    while (head < tail) {
        const size_t current = queue[head++];
        for (size_t next = 0; next < vertices; ++next) {
            if (adjacent[current * vertices + next] && distance[next] < 0) {
                distance[next] = distance[current] + 1;
                queue[tail++] = next;
            }
        }
    }
    return distance[target];
}
