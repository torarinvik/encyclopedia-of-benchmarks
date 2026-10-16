// Enumerate directed simple cycles in source DFS order.
#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_vertices = 6;
constexpr std::size_t max_edges = max_vertices * max_vertices;
constexpr std::size_t max_output_bytes = 2786;
}

extern "C" std::int64_t directed_simple_cycles(const std::int64_t *input, std::size_t length,
                                                 std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > static_cast<std::int64_t>(max_vertices) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_edges)) return -1;
    const std::size_t vertices = static_cast<std::size_t>(input[0]);
    const std::size_t edges = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edges) return -1;

    std::array<std::array<bool, max_vertices>, max_vertices> adjacency{};
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const std::int64_t source = input[2 + 2 * edge];
        const std::int64_t destination = input[3 + 2 * edge];
        if (source < 0 || static_cast<std::uint64_t>(source) >= vertices || destination < 0 ||
            static_cast<std::uint64_t>(destination) >= vertices) return -1;
        adjacency[static_cast<std::size_t>(source)][static_cast<std::size_t>(destination)] = true;
    }

    std::array<std::uint8_t, max_output_bytes> scratch{};
    std::size_t output_length = 0;
    for (std::size_t start = 0; start < vertices; ++start) {
        std::array<std::size_t, max_vertices> path{};
        std::array<std::size_t, max_vertices> next_neighbor{};
        std::array<bool, max_vertices> visited{};
        std::size_t depth = 0;
        path[0] = start;
        visited[start] = true;
        for (;;) {
            const std::size_t current = path[depth];
            if (next_neighbor[depth] == vertices) {
                visited[current] = false;
                if (depth == 0) break;
                --depth;
                continue;
            }
            const std::size_t neighbor = next_neighbor[depth]++;
            if (!adjacency[current][neighbor]) continue;
            if (neighbor == start) {
                for (std::size_t index = 0; index <= depth; ++index)
                    scratch[output_length++] = static_cast<std::uint8_t>(path[index]);
                scratch[output_length++] = static_cast<std::uint8_t>(start);
                scratch[output_length++] = 255;
            } else if (!visited[neighbor]) {
                ++depth;
                path[depth] = neighbor;
                next_neighbor[depth] = 0;
                visited[neighbor] = true;
            }
        }
        for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
            adjacency[start][vertex] = false;
            adjacency[vertex][start] = false;
        }
    }
    if (output_length == 0) return 0;
    if (output == nullptr || capacity < output_length) return -2;
    std::memcpy(output, scratch.data(), output_length);
    return static_cast<std::int64_t>(output_length);
}
