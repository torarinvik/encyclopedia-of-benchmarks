/* One-target directed BFS distance with vertices mapped to single characters. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 26;
constexpr std::size_t MAX_EDGES = 256;
}

extern "C" std::int64_t breadth_first_search_shortest_path_distance(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4) return -1;
    const auto vertices_value = input[0];
    const auto edges_value = input[1];
    const auto source_value = input[2];
    const auto target_value = input[3];
    if (vertices_value < 1 || vertices_value > static_cast<std::int64_t>(MAX_VERTICES) ||
        edges_value < 0 || edges_value > static_cast<std::int64_t>(MAX_EDGES)) return -1;
    const auto vertices = static_cast<std::size_t>(vertices_value);
    const auto edges = static_cast<std::size_t>(edges_value);
    if (source_value < 0 || source_value >= vertices_value || target_value < 0 || target_value >= vertices_value ||
        length != 4 + 2 * edges) return -1;

    bool adjacent[MAX_VERTICES * MAX_VERTICES]{};
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const auto from = input[4 + 2 * edge];
        const auto to = input[5 + 2 * edge];
        if (from < 0 || from >= vertices_value || to < 0 || to >= vertices_value) return -1;
        adjacent[static_cast<std::size_t>(from) * vertices + static_cast<std::size_t>(to)] = true;
    }

    const auto source = static_cast<std::size_t>(source_value);
    const auto target = static_cast<std::size_t>(target_value);
    std::int64_t distance[MAX_VERTICES];
    std::size_t queue[MAX_VERTICES];
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) distance[vertex] = -1;
    std::size_t head = 0, tail = 0;
    distance[source] = 0;
    queue[tail++] = source;
    while (head < tail) {
        const auto current = queue[head++];
        for (std::size_t next = 0; next < vertices; ++next) {
            if (adjacent[current * vertices + next] && distance[next] < 0) {
                distance[next] = distance[current] + 1;
                queue[tail++] = next;
            }
        }
    }
    return distance[target];
}
