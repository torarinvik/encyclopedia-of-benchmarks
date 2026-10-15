#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertexCount = 40;
constexpr std::size_t MaxEdgeCount = 2047;
constexpr std::size_t MaxInputLength = 2 + 2 * MaxEdgeCount;

void fill_order(const std::uint64_t *adjacency, std::size_t vertex_count, std::size_t vertex,
                bool *visited, std::size_t *order, std::size_t &order_length)
{
    visited[vertex] = true;
    for (std::size_t neighbor = 0; neighbor < vertex_count; ++neighbor)
        if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) != 0 && !visited[neighbor])
            fill_order(adjacency, vertex_count, neighbor, visited, order, order_length);
    order[order_length++] = vertex;
}

void collect_component(const std::uint64_t *transpose, std::size_t vertex_count, std::size_t vertex,
                       bool *visited, std::int64_t *component_id, std::int64_t id)
{
    visited[vertex] = true;
    component_id[vertex] = id;
    for (std::size_t neighbor = 0; neighbor < vertex_count; ++neighbor)
        if ((transpose[vertex] & (UINT64_C(1) << neighbor)) != 0 && !visited[neighbor])
            collect_component(transpose, vertex_count, neighbor, visited, component_id, id);
}

std::int64_t encode_components(const std::int64_t *component_id, std::size_t vertex_count,
                               std::size_t component_count, std::uint8_t *output,
                               std::size_t output_capacity)
{
    const std::size_t output_length = 1 + vertex_count + component_count;
    if (output_capacity < output_length || output == nullptr) return -2;
    output[0] = static_cast<std::uint8_t>(component_count);
    std::size_t position = 1;
    for (std::size_t first = 0; first < vertex_count; ++first) {
        const auto id = component_id[first];
        bool emitted = false;
        for (std::size_t earlier = 0; earlier < first; ++earlier)
            if (component_id[earlier] == id) emitted = true;
        if (emitted) continue;
        std::size_t size = 0;
        for (std::size_t vertex = first; vertex < vertex_count; ++vertex)
            if (component_id[vertex] == id) ++size;
        output[position++] = static_cast<std::uint8_t>(size);
        for (std::size_t vertex = first; vertex < vertex_count; ++vertex)
            if (component_id[vertex] == id) output[position++] = static_cast<std::uint8_t>(vertex);
    }
    return static_cast<std::int64_t>(output_length);
}
}

extern "C" std::int64_t kosaraju(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 2 || length > MaxInputLength || input[0] < 0 ||
        input[0] > static_cast<std::int64_t>(MaxVertexCount) || input[1] < 0 ||
        input[1] > static_cast<std::int64_t>(MaxEdgeCount)) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edge_count) return -1;
    std::uint64_t adjacency[MaxVertexCount]{}, transpose[MaxVertexCount]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto from_value = input[2 + 2 * edge], to_value = input[3 + 2 * edge];
        if (from_value < 0 || to_value < 0 || from_value >= static_cast<std::int64_t>(vertex_count) ||
            to_value >= static_cast<std::int64_t>(vertex_count)) return -1;
        const auto from = static_cast<std::size_t>(from_value), to = static_cast<std::size_t>(to_value);
        adjacency[from] |= UINT64_C(1) << to;
        transpose[to] |= UINT64_C(1) << from;
    }
    bool visited[MaxVertexCount]{};
    std::size_t order[MaxVertexCount], order_length = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (!visited[vertex]) fill_order(adjacency, vertex_count, vertex, visited, order, order_length);
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) visited[vertex] = false;
    std::int64_t component_id[MaxVertexCount];
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) component_id[vertex] = -1;
    std::size_t component_count = 0;
    while (order_length > 0) {
        const auto vertex = order[--order_length];
        if (!visited[vertex])
            collect_component(transpose, vertex_count, vertex, visited, component_id,
                              static_cast<std::int64_t>(component_count++));
    }
    return encode_components(component_id, vertex_count, component_count, output, output_capacity);
}
