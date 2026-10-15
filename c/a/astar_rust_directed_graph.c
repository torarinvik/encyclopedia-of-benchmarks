#include <stddef.h>
#include <stdint.h>
#include <limits.h>

static void put_i64_le(int64_t value, uint8_t *output, size_t offset) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t astar_rust_directed_graph(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 4) return -1;
    const int64_t vertex_count = input[0], edge_count = input[1];
    if (vertex_count < 1 || vertex_count > 32 || edge_count < 0 || edge_count > 128) return -1;
    if (length != 4 + (size_t)vertex_count + 3 * (size_t)edge_count) return -1;
    const int64_t start = input[2], goal = input[3];
    if (start < 0 || start >= vertex_count || goal < 0 || goal >= vertex_count) return -1;
    const int64_t *heuristic = input + 4;
    const int64_t *edges = heuristic + vertex_count;
    for (int64_t v = 0; v < vertex_count; ++v) {
        if (heuristic[v] < 0 || heuristic[v] > 1000000) return -1;
    }
    if (heuristic[goal] != 0) return -1;
    for (int64_t e = 0; e < edge_count; ++e) {
        const int64_t from = edges[3 * e], to = edges[3 * e + 1], weight = edges[3 * e + 2];
        if (from < 0 || from >= vertex_count || to < 0 || to >= vertex_count || weight < 0 || weight > 1000000) return -1;
        if (heuristic[from] > weight + heuristic[to]) return -1;
    }
    int64_t distance[32], parent[32];
    uint8_t closed[32] = {0};
    for (int64_t v = 0; v < vertex_count; ++v) { distance[v] = INT64_MAX; parent[v] = -1; }
    distance[start] = 0;
    for (int64_t step = 0; step < vertex_count; ++step) {
        int64_t current = -1;
        for (int64_t v = 0; v < vertex_count; ++v) {
            if (closed[v] || distance[v] == INT64_MAX) continue;
            if (current < 0 || distance[v] + heuristic[v] < distance[current] + heuristic[current] ||
                (distance[v] + heuristic[v] == distance[current] + heuristic[current] &&
                 (distance[v] < distance[current] || (distance[v] == distance[current] && v < current)))) current = v;
        }
        if (current < 0) break;
        if (current == goal) break;
        closed[current] = 1;
        for (int64_t e = 0; e < edge_count; ++e) {
            if (edges[3 * e] != current) continue;
            const int64_t next = edges[3 * e + 1], candidate = distance[current] + edges[3 * e + 2];
            if (!closed[next] && candidate < distance[next]) { distance[next] = candidate; parent[next] = current; }
        }
    }
    if (distance[goal] == INT64_MAX) return 0;
    int64_t reversed[32], path_length = 0, current = goal;
    while (path_length < vertex_count) {
        reversed[path_length++] = current;
        if (current == start) break;
        current = parent[current];
        if (current < 0) return -1;
    }
    if (reversed[path_length - 1] != start) return -1;
    const size_t required = 8 * ((size_t)path_length + 2);
    if (!output || capacity < required) return -2;
    put_i64_le(distance[goal], output, 0);
    put_i64_le(path_length, output, 8);
    for (int64_t i = 0; i < path_length; ++i) put_i64_le(reversed[path_length - 1 - i], output, 16 + (size_t)i * 8);
    return (int64_t)required;
}
