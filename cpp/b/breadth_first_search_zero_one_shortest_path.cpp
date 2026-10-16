#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_vertices = 64;
constexpr int max_edges = 256;
constexpr std::size_t max_input_length = 4 + 3 * max_edges;
constexpr std::size_t max_deque_capacity = max_vertices * max_vertices + 1;
}

extern "C" std::int64_t breadth_first_search_zero_one_shortest_path(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > max_input_length) return -2;
    const auto vertex_value = input[0], edge_value = input[1], start_value = input[2], finish_value = input[3];
    if (vertex_value < 1 || vertex_value > max_vertices || edge_value < 0 || edge_value > max_edges) return -2;
    const int vertices = static_cast<int>(vertex_value), edges = static_cast<int>(edge_value);
    if (length != static_cast<std::size_t>(4 + 3 * edges) || start_value < 0 || start_value >= vertices || finish_value < 0 || finish_value >= vertices) return -2;

    int edge_to[max_edges], edge_weight[max_edges], next_edge[max_edges];
    int head_edge[max_vertices], tail_edge[max_vertices];
    for (int vertex = 0; vertex < vertices; ++vertex) head_edge[vertex] = tail_edge[vertex] = -1;
    for (int edge = 0; edge < edges; ++edge) {
        const auto from = input[4 + 3 * edge], to = input[5 + 3 * edge], weight = input[6 + 3 * edge];
        if (from < 0 || from >= vertices || to < 0 || to >= vertices || (weight != 0 && weight != 1)) return -2;
        edge_to[edge] = static_cast<int>(to);
        edge_weight[edge] = static_cast<int>(weight);
        next_edge[edge] = -1;
        const int source = static_cast<int>(from);
        if (head_edge[source] < 0) head_edge[source] = edge;
        else next_edge[tail_edge[source]] = edge;
        tail_edge[source] = edge;
    }
    const int start = static_cast<int>(start_value), finish = static_cast<int>(finish_value);
    std::int64_t distance[max_vertices];
    for (int vertex = 0; vertex < vertices; ++vertex) distance[vertex] = INT64_MAX;
    int deque[max_deque_capacity];
    std::size_t deque_head = 0, deque_count = 0;
    distance[start] = 0;
    deque[deque_head] = start;
    deque_count = 1;
    while (deque_count > 0) {
        const int node = deque[deque_head];
        deque_head = (deque_head + 1) % max_deque_capacity;
        --deque_count;
        for (int edge = head_edge[node]; edge >= 0; edge = next_edge[edge]) {
            const int neighbor = edge_to[edge];
            const auto candidate = distance[node] + edge_weight[edge];
            if (candidate >= distance[neighbor]) continue;
            distance[neighbor] = candidate;
            if (edge_weight[edge] == 0) {
                deque_head = (deque_head + max_deque_capacity - 1) % max_deque_capacity;
                deque[deque_head] = neighbor;
            } else {
                deque[(deque_head + deque_count) % max_deque_capacity] = neighbor;
            }
            ++deque_count;
        }
    }
    return distance[finish] == INT64_MAX ? -1 : distance[finish];
}
