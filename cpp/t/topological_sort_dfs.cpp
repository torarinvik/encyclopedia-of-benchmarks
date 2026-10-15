/* Deterministic depth-first topological sort over a bounded directed graph. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t topological_sort_dfs(const std::int64_t *values, std::size_t length,
                                              std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 40) return -2;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto edge_count = (length - 1) / 2;
    std::uint64_t adjacency[40]{};
    std::uint8_t state[40]{};
    std::size_t stack[40], next_neighbor[40], order[40];

    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin_value = values[1 + 2 * edge];
        const auto destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(origin_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices) return -2;
        adjacency[static_cast<std::size_t>(origin_value)] |=
            UINT64_C(1) << static_cast<std::size_t>(destination_value);
    }

    std::size_t count = 0;
    for (std::size_t root = 0; root < vertices; ++root) {
        if (state[root] != 0) continue;
        std::size_t top = 0;
        stack[top] = root;
        next_neighbor[top] = 0;
        state[root] = 1;
        for (;;) {
            const auto origin = stack[top];
            auto destination = next_neighbor[top];
            while (destination < vertices &&
                   (adjacency[origin] & (UINT64_C(1) << destination)) == 0) ++destination;
            if (destination == vertices) {
                state[origin] = 2;
                order[count++] = origin;
                if (top == 0) break;
                --top;
                continue;
            }
            next_neighbor[top] = destination + 1;
            if (state[destination] == 1) return -1;
            if (state[destination] == 0) {
                ++top;
                stack[top] = destination;
                next_neighbor[top] = 0;
                state[destination] = 1;
            }
        }
    }

    if (output_capacity < vertices || (vertices != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index)
        output[index] = static_cast<std::uint8_t>(order[count - 1 - index]);
    return static_cast<std::int64_t>(count);
}
