#include <cstddef>
#include <cstdint>

// Stack-based DFS that marks vertices when they are pushed, matching the source order.
extern "C" std::int64_t depth_first_search_with_stack(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > 66 || (length - 2) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto start_value = values[1];
    if (vertices == 0) return start_value == -1 && length == 2 ? 0 : -2;
    if (start_value < 0 || static_cast<std::uint64_t>(start_value) >= vertices) return -2;

    std::size_t adjacency[64 * 32]{};
    std::size_t degree[64]{};
    std::uint8_t state[64]{};
    const auto edge_count = (length - 2) / 2;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin_value = values[2 + 2 * edge];
        const auto destination_value = values[3 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(origin_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices) return -2;
        const auto origin = static_cast<std::size_t>(origin_value);
        adjacency[origin * 32 + degree[origin]++] = static_cast<std::size_t>(destination_value);
    }

    std::size_t stack[33]{};
    std::size_t stack_length = 1;
    std::size_t order[64]{};
    std::size_t count = 0;
    const auto start = static_cast<std::size_t>(start_value);
    state[start] = 1;
    stack[0] = start;
    while (stack_length != 0) {
        const auto vertex = stack[--stack_length];
        if (state[vertex] != 1) continue;
        order[count++] = vertex;
        for (std::size_t edge = 0; edge < degree[vertex]; ++edge) {
            const auto neighbor = adjacency[vertex * 32 + edge];
            stack[stack_length++] = neighbor;
            if (state[neighbor] != 2) state[neighbor] = 1;
        }
        state[vertex] = 2;
    }
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index)
        output[index] = static_cast<std::uint8_t>(order[index]);
    return static_cast<std::int64_t>(count);
}
