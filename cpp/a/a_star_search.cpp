#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t a_star_search(const int64_t *input, size_t length,
                                  uint8_t *output, size_t output_capacity) {
    constexpr size_t max_vertices = 256, max_edges = 4096;
    constexpr int64_t inf = INT64_MAX / 4;
    if (input == nullptr || length < 5 || length > 4 + max_vertices + 2 * max_edges) return -1;
    const int64_t vertex_value = input[0], edge_value = input[1];
    const int64_t source_value = input[2], target_value = input[3];
    if (vertex_value < 1 || vertex_value > static_cast<int64_t>(max_vertices) ||
        edge_value < 0 || edge_value > static_cast<int64_t>(max_edges) ||
        source_value < 0 || source_value >= vertex_value ||
        target_value < 0 || target_value >= vertex_value) return -1;
    const size_t vertices = static_cast<size_t>(vertex_value), edges = static_cast<size_t>(edge_value);
    const size_t source = static_cast<size_t>(source_value), target = static_cast<size_t>(target_value);
    if (length != 4 + vertices + 2 * edges) return -1;

    std::array<int64_t, max_vertices> heuristic{}, distance{}, parent{}, reversed{};
    std::array<int64_t, max_edges> from{}, to{};
    std::array<bool, max_vertices> opened{}, closed{};
    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        heuristic[vertex] = input[4 + vertex];
        if (heuristic[vertex] < 0 || heuristic[vertex] > 1000000000) return -1;
        distance[vertex] = inf;
        parent[vertex] = -1;
    }
    if (heuristic[target] != 0) return -1;
    const size_t edge_offset = 4 + vertices;
    for (size_t edge = 0; edge < edges; ++edge) {
        const int64_t u = input[edge_offset + 2 * edge], v = input[edge_offset + 2 * edge + 1];
        if (u < 0 || u >= vertex_value || v < 0 || v >= vertex_value ||
            heuristic[static_cast<size_t>(u)] > heuristic[static_cast<size_t>(v)] + 1) return -1;
        from[edge] = u;
        to[edge] = v;
    }

    distance[source] = 0;
    opened[source] = true;
    while (true) {
        size_t best = vertices;
        for (size_t vertex = 0; vertex < vertices; ++vertex) {
            if (!opened[vertex]) continue;
            if (best == vertices || distance[vertex] + heuristic[vertex] < distance[best] + heuristic[best] ||
                (distance[vertex] + heuristic[vertex] == distance[best] + heuristic[best] &&
                 (distance[vertex] < distance[best] ||
                  (distance[vertex] == distance[best] && vertex < best)))) best = vertex;
        }
        if (best == vertices) break;
        opened[best] = false;
        closed[best] = true;
        if (best == target) break;
        for (size_t edge = 0; edge < edges; ++edge) {
            if (static_cast<size_t>(from[edge]) != best) continue;
            const size_t neighbor = static_cast<size_t>(to[edge]);
            if (closed[neighbor]) continue;
            const int64_t candidate = distance[best] + 1;
            if (candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                parent[neighbor] = static_cast<int64_t>(best);
                opened[neighbor] = true;
            }
        }
    }
    if (distance[target] == inf) return 0;
    size_t path_length = 0;
    int64_t current = static_cast<int64_t>(target);
    while (current >= 0 && path_length < vertices) {
        reversed[path_length++] = current;
        if (static_cast<size_t>(current) == source) break;
        current = parent[static_cast<size_t>(current)];
    }
    if (path_length == 0 || static_cast<size_t>(reversed[path_length - 1]) != source ||
        path_length - 1 > 30) return -1;
    if (output_capacity < path_length || output == nullptr) return -2;
    for (size_t index = 0; index < path_length; ++index)
        output[index] = static_cast<uint8_t>(reversed[path_length - 1 - index]);
    return static_cast<int64_t>(path_length);
}
