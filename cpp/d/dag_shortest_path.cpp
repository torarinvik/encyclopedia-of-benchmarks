#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 12;
constexpr std::size_t max_edges = 66;
constexpr std::size_t max_length = 203;
constexpr std::int64_t distance_offset = 100000;
constexpr std::int64_t infinity_distance = INT64_C(1) << 60;
}

extern "C" std::int64_t dag_shortest_path(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 4 || length > max_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices)
            || input[1] < 0 || input[1] > static_cast<std::int64_t>(max_edges)) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 4 + 3 * edge_count || input[2] < 0 || input[2] >= static_cast<std::int64_t>(vertex_count)
            || input[3] < 0 || input[3] >= static_cast<std::int64_t>(vertex_count)) return -1;
    std::int64_t from[max_edges], to[max_edges], weight[max_edges];
    std::int64_t indegree[max_vertices] = {}, queue[max_vertices], order[max_vertices];
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto start = input[4 + 3 * edge], end = input[5 + 3 * edge], cost = input[6 + 3 * edge];
        if (start < 0 || start >= static_cast<std::int64_t>(vertex_count)
                || end < 0 || end >= static_cast<std::int64_t>(vertex_count)
                || start == end || cost < -1000 || cost > 1000) return -1;
        for (std::size_t previous = 0; previous < edge; ++previous)
            if (from[previous] == start && to[previous] == end) return -1;
        from[edge] = start; to[edge] = end; weight[edge] = cost;
        ++indegree[static_cast<std::size_t>(end)];
    }
    std::size_t head = 0, tail = 0, order_count = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (indegree[vertex] == 0) queue[tail++] = static_cast<std::int64_t>(vertex);
    while (head < tail) {
        const auto vertex = queue[head++];
        order[order_count++] = vertex;
        for (std::size_t edge = 0; edge < edge_count; ++edge) if (from[edge] == vertex) {
            auto &degree = indegree[static_cast<std::size_t>(to[edge])];
            if (--degree == 0) queue[tail++] = to[edge];
        }
    }
    if (order_count != vertex_count) return -1;
    std::int64_t distance[max_vertices];
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) distance[vertex] = infinity_distance;
    distance[static_cast<std::size_t>(input[2])] = 0;
    for (std::size_t position = 0; position < vertex_count; ++position) {
        const auto vertex = order[position];
        if (distance[static_cast<std::size_t>(vertex)] == infinity_distance) continue;
        for (std::size_t edge = 0; edge < edge_count; ++edge) if (from[edge] == vertex) {
            const auto end = static_cast<std::size_t>(to[edge]);
            const auto candidate = distance[static_cast<std::size_t>(vertex)] + weight[edge];
            if (candidate < distance[end]) distance[end] = candidate;
        }
    }
    const auto answer = distance[static_cast<std::size_t>(input[3])];
    return answer == infinity_distance ? 0 : distance_offset + answer;
}
