/* Detect directed cycles with iterative three-color depth-first search. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t check_cycle(const std::int64_t *input,
                                    std::size_t length) noexcept
{
    constexpr std::size_t max_vertices = 32;
    constexpr std::size_t max_edges = 256;
    constexpr std::size_t max_matrix = max_vertices * max_vertices;
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 32 ||
        input[1] < 0 || input[1] > 256) return -1;
    const auto vertices = static_cast<std::size_t>(input[0]);
    const auto edges = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edges) return -1;

    std::array<bool, max_matrix> adjacency{};
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const auto origin = input[2 + 2 * edge];
        const auto destination = input[3 + 2 * edge];
        if (origin < 0 || origin >= static_cast<std::int64_t>(vertices) ||
            destination < 0 || destination >= static_cast<std::int64_t>(vertices)) return -1;
        adjacency[static_cast<std::size_t>(origin) * max_vertices + static_cast<std::size_t>(destination)] = true;
    }

    std::array<std::uint8_t, max_vertices> color{};
    std::array<std::size_t, max_vertices> stack{};
    std::array<std::size_t, max_vertices> next_neighbor{};
    for (std::size_t start = 0; start < vertices; ++start) {
        if (color[start] != 0) continue;
        std::size_t top = 1;
        stack[0] = start;
        next_neighbor[0] = 0;
        color[start] = 1;
        while (top != 0) {
            const auto frame = top - 1;
            const auto current = stack[frame];
            while (next_neighbor[frame] < vertices &&
                   !adjacency[current * max_vertices + next_neighbor[frame]]) ++next_neighbor[frame];
            if (next_neighbor[frame] == vertices) {
                color[current] = 2;
                --top;
                continue;
            }
            const auto neighbor = next_neighbor[frame]++;
            if (color[neighbor] == 1) return 1;
            if (color[neighbor] == 0) {
                color[neighbor] = 1;
                stack[top] = neighbor;
                next_neighbor[top] = 0;
                ++top;
            }
        }
    }
    return 0;
}
