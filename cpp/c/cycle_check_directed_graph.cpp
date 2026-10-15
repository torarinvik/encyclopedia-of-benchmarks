#include <cstddef>
#include <cstdint>

namespace {
bool has_cycle_dfs(std::size_t origin, std::size_t vertices,
                   const std::uint64_t adjacency[64], std::uint8_t state[64],
                   std::size_t stack[64], std::size_t next_neighbor[64]) noexcept
{
    std::size_t top = 0;
    stack[0] = origin;
    next_neighbor[0] = 0;
    state[origin] = 1;
    for (;;) {
        const auto node = stack[top];
        auto destination = next_neighbor[top];
        while (destination < vertices &&
               (adjacency[node] & (UINT64_C(1) << destination)) == 0) ++destination;
        if (destination == vertices) {
            state[node] = 2;
            if (top == 0) return false;
            --top;
            continue;
        }
        next_neighbor[top] = destination + 1;
        if (state[destination] == 1) return true;
        if (state[destination] == 0) {
            ++top;
            stack[top] = destination;
            next_neighbor[top] = 0;
            state[destination] = 1;
        }
    }
}
} // namespace

extern "C" std::int64_t cycle_check_directed_graph(const std::int64_t *values,
                                                    std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > 65 || (length - 1) % 2 != 0) return -1;
    if (values[0] < 0 || values[0] > 64) return -1;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto edge_count = (length - 1) / 2;
    if (edge_count > 32) return -1;
    std::uint64_t adjacency[64]{};
    std::uint8_t state[64]{};
    std::size_t stack[64], next_neighbor[64];
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto source_value = values[1 + 2 * edge];
        const auto destination_value = values[2 + 2 * edge];
        if (source_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(source_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices) return -1;
        adjacency[static_cast<std::size_t>(source_value)] |=
            UINT64_C(1) << static_cast<std::size_t>(destination_value);
    }
    for (std::size_t root = 0; root < vertices; ++root)
        if (state[root] == 0 && has_cycle_dfs(root, vertices, adjacency, state, stack, next_neighbor)) return 1;
    return 0;
}
