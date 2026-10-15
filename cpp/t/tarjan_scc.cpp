#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertexCount = 40;
constexpr std::size_t MaxEdgeCount = 2047;
constexpr std::size_t MaxInputLength = 2 + 2 * MaxEdgeCount;

void visit_vertex(const std::uint64_t *adjacency, std::size_t vertex_count, std::size_t vertex,
                  bool *on_stack, std::size_t *stack, std::size_t &stack_length,
                  std::int64_t *discovery, std::int64_t *low, std::int64_t *component_id,
                  std::size_t &time, std::size_t &component_count)
{
    discovery[vertex] = low[vertex] = static_cast<std::int64_t>(time++);
    on_stack[vertex] = true;
    stack[stack_length++] = vertex;
    for (std::size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
        if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) == 0) continue;
        if (discovery[neighbor] == -1) {
            visit_vertex(adjacency, vertex_count, neighbor, on_stack, stack, stack_length,
                         discovery, low, component_id, time, component_count);
            if (low[neighbor] < low[vertex]) low[vertex] = low[neighbor];
        } else if (on_stack[neighbor] && discovery[neighbor] < low[vertex]) {
            low[vertex] = discovery[neighbor];
        }
    }
    if (low[vertex] == discovery[vertex]) {
        while (stack_length > 0) {
            const auto member = stack[--stack_length];
            on_stack[member] = false;
            component_id[member] = static_cast<std::int64_t>(component_count);
            if (member == vertex) break;
        }
        ++component_count;
    }
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

extern "C" std::int64_t tarjan_scc(const std::int64_t *input, std::size_t length,
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
        const auto from_value = input[2 + 2 * edge], to_value = input[3 + 2 * edge];
        if (from_value < 0 || to_value < 0 || from_value >= static_cast<std::int64_t>(vertex_count) ||
            to_value >= static_cast<std::int64_t>(vertex_count)) return -1;
        const auto from = static_cast<std::size_t>(from_value), to = static_cast<std::size_t>(to_value);
        adjacency[from] |= UINT64_C(1) << to;
    }
    bool on_stack[MaxVertexCount]{};
    std::size_t stack[MaxVertexCount], stack_length = 0, time = 0, component_count = 0;
    std::int64_t discovery[MaxVertexCount], low[MaxVertexCount], component_id[MaxVertexCount];
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        discovery[vertex] = -1;
        low[vertex] = 0;
        component_id[vertex] = -1;
    }
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (discovery[vertex] == -1)
            visit_vertex(adjacency, vertex_count, vertex, on_stack, stack, stack_length,
                         discovery, low, component_id, time, component_count);
    return encode_components(component_id, vertex_count, component_count, output, output_capacity);
}
