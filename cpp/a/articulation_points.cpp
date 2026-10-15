#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertexCount = 64;
constexpr std::size_t MaxEdgeCount = 2047;
constexpr std::size_t MaxInputLength = 2 + 2 * MaxEdgeCount;

void visit_vertex(const std::uint64_t *adjacency, std::size_t vertex_count, std::size_t vertex,
                  std::int64_t *discovery, std::int64_t *low, std::int64_t *parent,
                  bool *is_articulation, std::size_t &time)
{
    discovery[vertex] = low[vertex] = static_cast<std::int64_t>(time++);
    std::size_t child_count = 0;
    for (std::size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
        if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) == 0) continue;
        if (discovery[neighbor] == -1) {
            parent[neighbor] = static_cast<std::int64_t>(vertex);
            ++child_count;
            visit_vertex(adjacency, vertex_count, neighbor, discovery, low, parent,
                         is_articulation, time);
            if (low[neighbor] < low[vertex]) low[vertex] = low[neighbor];
            if (parent[vertex] == -1 && child_count > 1) is_articulation[vertex] = true;
            if (parent[vertex] != -1 && low[neighbor] >= discovery[vertex])
                is_articulation[vertex] = true;
        } else if (static_cast<std::int64_t>(neighbor) != parent[vertex] &&
                   discovery[neighbor] < low[vertex]) {
            low[vertex] = discovery[neighbor];
        }
    }
}
}

extern "C" std::int64_t articulation_points(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 2 || length > MaxInputLength || input[0] < 0 ||
        input[0] > static_cast<std::int64_t>(MaxVertexCount) || input[1] < 0 ||
        input[1] > static_cast<std::int64_t>(MaxEdgeCount)) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edge_count) return -1;
    std::uint64_t adjacency[MaxVertexCount]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left_value = input[2 + 2 * edge], right_value = input[3 + 2 * edge];
        if (left_value < 0 || right_value < 0 || left_value >= static_cast<std::int64_t>(vertex_count) ||
            right_value >= static_cast<std::int64_t>(vertex_count)) return -1;
        const auto left = static_cast<std::size_t>(left_value), right = static_cast<std::size_t>(right_value);
        adjacency[left] |= UINT64_C(1) << right;
        adjacency[right] |= UINT64_C(1) << left;
    }

    std::int64_t discovery[MaxVertexCount], low[MaxVertexCount], parent[MaxVertexCount];
    bool is_articulation[MaxVertexCount]{};
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        discovery[vertex] = -1;
        low[vertex] = 0;
        parent[vertex] = -1;
    }
    std::size_t time = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (discovery[vertex] == -1)
            visit_vertex(adjacency, vertex_count, vertex, discovery, low, parent,
                         is_articulation, time);
    std::size_t point_count = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (is_articulation[vertex]) ++point_count;
    if (output_capacity < point_count || (point_count != 0 && output == nullptr)) return -2;
    std::size_t position = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (is_articulation[vertex]) output[position++] = static_cast<std::uint8_t>(vertex);
    return static_cast<std::int64_t>(point_count);
}
