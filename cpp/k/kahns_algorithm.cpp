#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 32;
constexpr std::size_t MAX_EDGES = 128;
constexpr std::size_t MAX_INPUT_LENGTH = 1 + 2 * MAX_EDGES;

int find_vertex(const std::int32_t *labels, std::size_t vertex_count, std::int32_t label) {
    for (std::size_t i = 0; i < vertex_count; ++i)
        if (labels[i] == label) return static_cast<int>(i);
    return -1;
}
}

extern "C" std::int64_t kahns_algorithm(const std::int64_t *input, std::size_t length,
                                        std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t edge_count_value = input[0];
    if (edge_count_value < 0 || edge_count_value > static_cast<std::int64_t>(MAX_EDGES)) return -1;
    const std::size_t edge_count = static_cast<std::size_t>(edge_count_value);
    if (length != 1 + 2 * edge_count) return -1;

    std::int32_t labels[MAX_VERTICES]{};
    int first_edge[MAX_VERTICES], tail_edge[MAX_VERTICES], next_edge[MAX_EDGES];
    std::size_t to[MAX_EDGES]{}, indegree[MAX_VERTICES]{};
    std::size_t vertex_count = 0;
    for (std::size_t vertex = 0; vertex < MAX_VERTICES; ++vertex)
        first_edge[vertex] = tail_edge[vertex] = -1;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const std::int64_t from_value = input[1 + 2 * edge], to_value = input[2 + 2 * edge];
        if (from_value < INT32_MIN || from_value > INT32_MAX ||
            to_value < INT32_MIN || to_value > INT32_MAX) return -1;
        const auto from_label = static_cast<std::int32_t>(from_value);
        const auto to_label = static_cast<std::int32_t>(to_value);
        int from_index = find_vertex(labels, vertex_count, from_label);
        if (from_index < 0) {
            if (vertex_count >= MAX_VERTICES) return -1;
            from_index = static_cast<int>(vertex_count);
            labels[vertex_count++] = from_label;
        }
        int to_index = find_vertex(labels, vertex_count, to_label);
        if (to_index < 0) {
            if (vertex_count >= MAX_VERTICES) return -1;
            to_index = static_cast<int>(vertex_count);
            labels[vertex_count++] = to_label;
        }
        to[edge] = static_cast<std::size_t>(to_index);
        next_edge[edge] = -1;
        if (first_edge[static_cast<std::size_t>(from_index)] < 0)
            first_edge[static_cast<std::size_t>(from_index)] = static_cast<int>(edge);
        else
            next_edge[static_cast<std::size_t>(tail_edge[static_cast<std::size_t>(from_index)])] = static_cast<int>(edge);
        tail_edge[static_cast<std::size_t>(from_index)] = static_cast<int>(edge);
        ++indegree[static_cast<std::size_t>(to_index)];
    }

    std::size_t queue[MAX_VERTICES]{}, order[MAX_VERTICES]{};
    std::size_t queue_head = 0, queue_tail = 0, order_count = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (indegree[vertex] == 0) queue[queue_tail++] = vertex;
    if (vertex_count > 0 && queue_tail != 1) return -1;
    while (queue_head < queue_tail) {
        if (queue_tail - queue_head != 1) return -1;
        const std::size_t current = queue[queue_head++];
        order[order_count++] = current;
        for (int outgoing = first_edge[current]; outgoing >= 0; outgoing = next_edge[static_cast<std::size_t>(outgoing)]) {
            const std::size_t adjacent = to[static_cast<std::size_t>(outgoing)];
            if (indegree[adjacent] == 0) return -1;
            --indegree[adjacent];
            if (indegree[adjacent] == 0) queue[queue_tail++] = adjacent;
        }
    }
    if (order_count != vertex_count) return -1;

    const std::size_t output_bytes = 4 * order_count;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < order_count; ++i) {
        std::uint32_t bits = static_cast<std::uint32_t>(labels[order[i]]);
        for (std::size_t byte = 0; byte < 4; ++byte) {
            output[4 * i + byte] = static_cast<std::uint8_t>(bits & UINT32_C(255));
            bits >>= 8;
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
