#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32;
constexpr std::size_t max_edges = 256;
constexpr std::size_t max_input_length = 4 + 2 * max_edges;
constexpr std::size_t max_output_values = 1 + max_vertices;
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t breadth_first_search_shortest_path(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const auto vertex_value = input[0], edge_value = input[1], start_value = input[2], goal_value = input[3];
    if (vertex_value < 1 || vertex_value > static_cast<std::int64_t>(max_vertices) || edge_value < 0 || edge_value > static_cast<std::int64_t>(max_edges)) return -1;
    const int vertices = static_cast<int>(vertex_value), edges = static_cast<int>(edge_value);
    if (length != static_cast<std::size_t>(4 + 2 * edges) || start_value < 0 || start_value >= vertices || goal_value < 0 || goal_value >= vertices) return -1;
    int adjacency[max_vertices * max_edges], degree[max_vertices] = {};
    for (int edge = 0; edge < edges; ++edge) {
        const auto from = input[4 + 2 * edge], to = input[5 + 2 * edge];
        if (from < 0 || from >= vertices || to < 0 || to >= vertices) return -1;
        const int source = static_cast<int>(from);
        adjacency[source * max_edges + degree[source]++] = static_cast<int>(to);
    }
    const int start = static_cast<int>(start_value), goal = static_cast<int>(goal_value);
    std::int64_t parent[max_vertices];
    bool visited[max_vertices] = {};
    int queue[max_vertices], head = 0, tail = 0;
    for (int vertex = 0; vertex < vertices; ++vertex) parent[vertex] = -1;
    visited[start] = true;
    queue[tail++] = start;
    while (head < tail && !visited[goal]) {
        const int node = queue[head++];
        for (int index = 0; index < degree[node]; ++index) {
            const int neighbor = adjacency[node * max_edges + index];
            if (visited[neighbor]) continue;
            visited[neighbor] = true;
            parent[neighbor] = node;
            queue[tail++] = neighbor;
            if (neighbor == goal) break;
        }
    }
    std::int64_t encoded[max_output_values];
    std::size_t path_count = 0;
    if (visited[goal]) {
        int reverse_path[max_vertices];
        int current = goal;
        while (current >= 0) {
            reverse_path[path_count++] = current;
            if (current == start) break;
            current = static_cast<int>(parent[current]);
        }
        for (std::size_t index = 0; index < path_count; ++index) encoded[1 + index] = reverse_path[path_count - 1 - index];
    }
    encoded[0] = static_cast<std::int64_t>(path_count);
    const std::size_t output_bytes = (path_count + 1) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index <= path_count; ++index) put_i64_le(output, index * 8, encoded[index]);
    return static_cast<std::int64_t>(output_bytes);
}
