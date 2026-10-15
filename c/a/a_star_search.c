#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 256
#define MAX_EDGES 4096
#define INF (INT64_MAX / 4)

int64_t a_star_search(const int64_t *input, size_t length, uint8_t *output,
                      size_t output_capacity) {
    if (input == NULL || length < 5 || length > 4 + MAX_VERTICES + 2 * MAX_EDGES) return -1;
    const int64_t vertex_value = input[0], edge_value = input[1];
    const int64_t source_value = input[2], target_value = input[3];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 ||
        edge_value > MAX_EDGES || source_value < 0 || source_value >= vertex_value ||
        target_value < 0 || target_value >= vertex_value) return -1;
    const size_t vertices = (size_t)vertex_value, edges = (size_t)edge_value;
    const size_t source = (size_t)source_value, target = (size_t)target_value;
    if (length != 4 + vertices + 2 * edges) return -1;

    int64_t heuristic[MAX_VERTICES], from[MAX_EDGES], to[MAX_EDGES];
    int64_t distance[MAX_VERTICES], parent[MAX_VERTICES], reversed[MAX_VERTICES];
    uint8_t opened[MAX_VERTICES] = {0}, closed[MAX_VERTICES] = {0};
    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        heuristic[vertex] = input[4 + vertex];
        if (heuristic[vertex] < 0 || heuristic[vertex] > 1000000000) return -1;
        distance[vertex] = INF;
        parent[vertex] = -1;
    }
    if (heuristic[target] != 0) return -1;
    const size_t edge_offset = 4 + vertices;
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t u = input[edge_offset + 2 * edge];
        const int64_t v = input[edge_offset + 2 * edge + 1];
        if (u < 0 || u >= vertex_value || v < 0 || v >= vertex_value ||
            heuristic[u] > heuristic[v] + 1) return -1;
        from[edge] = u;
        to[edge] = v;
    }

    distance[source] = 0;
    opened[source] = 1;
    while (1) {
        size_t best = vertices;
        for (size_t vertex = 0; vertex < vertices; ++vertex) {
            if (!opened[vertex]) continue;
            if (best == vertices || distance[vertex] + heuristic[vertex] < distance[best] + heuristic[best] ||
                (distance[vertex] + heuristic[vertex] == distance[best] + heuristic[best] &&
                 (distance[vertex] < distance[best] ||
                  (distance[vertex] == distance[best] && vertex < best)))) best = vertex;
        }
        if (best == vertices) break;
        opened[best] = 0;
        closed[best] = 1;
        if (best == target) break;
        for (size_t edge = 0; edge < edges; ++edge) {
            if ((size_t)from[edge] != best) continue;
            const size_t neighbor = (size_t)to[edge];
            if (closed[neighbor]) continue;
            const int64_t candidate = distance[best] + 1;
            if (candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                parent[neighbor] = (int64_t)best;
                opened[neighbor] = 1;
            }
        }
    }
    if (distance[target] == INF) return 0;
    size_t path_length = 0;
    int64_t current = (int64_t)target;
    while (current >= 0 && path_length < vertices) {
        reversed[path_length++] = current;
        if ((size_t)current == source) break;
        current = parent[current];
    }
    if (path_length == 0 || (size_t)reversed[path_length - 1] != source ||
        path_length - 1 > 30) return -1;
    if (output_capacity < path_length || output == NULL) return -2;
    for (size_t index = 0; index < path_length; ++index)
        output[index] = (uint8_t)reversed[path_length - 1 - index];
    return (int64_t)path_length;
}
