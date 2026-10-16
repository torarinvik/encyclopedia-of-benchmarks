/* Construct a directed Eulerian path with iterative Hierholzer traversal. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32;
constexpr std::size_t max_edges = 256;

void put_i64(std::uint8_t *output, std::size_t byte_offset, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte_offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}
}

extern "C" std::int64_t eulerian_path(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 32 ||
        input[1] < 0 || input[1] > 256) return -1;
    const auto vertices = static_cast<std::size_t>(input[0]);
    const auto edges = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edges) return -1;

    std::array<std::array<std::uint8_t, max_edges>, max_vertices> adjacency{};
    std::array<std::size_t, max_vertices> in_degree{};
    std::array<std::size_t, max_vertices> out_degree{};
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const auto source = input[2 + 2 * edge];
        const auto destination = input[3 + 2 * edge];
        if (source < 0 || source >= static_cast<std::int64_t>(vertices) || destination < 0 ||
            destination >= static_cast<std::int64_t>(vertices)) return -1;
        adjacency[static_cast<std::size_t>(source)][out_degree[static_cast<std::size_t>(source)]++] =
            static_cast<std::uint8_t>(destination);
        ++in_degree[static_cast<std::size_t>(destination)];
    }
    if (edges == 0) return 0;

    std::size_t start = 0;
    std::size_t start_count = 0;
    std::size_t end_count = 0;
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) {
        const auto difference = static_cast<std::int64_t>(out_degree[vertex]) -
                                static_cast<std::int64_t>(in_degree[vertex]);
        if (difference == 1) { start = vertex; ++start_count; }
        else if (difference == -1) ++end_count;
        else if (difference != 0) return 0;
    }
    if (!((start_count == 0 && end_count == 0) || (start_count == 1 && end_count == 1))) return 0;
    if (start_count == 0) {
        while (start < vertices && out_degree[start] == 0) ++start;
        if (start == vertices) return 0;
    }

    auto remaining = out_degree;
    std::array<std::size_t, max_edges + 1> stack{};
    std::array<std::size_t, max_edges + 1> reverse_path{};
    std::size_t top = 1;
    std::size_t path_count = 0;
    stack[0] = start;
    while (top != 0) {
        const auto current = stack[top - 1];
        if (remaining[current] != 0) {
            const auto index = --remaining[current];
            stack[top++] = adjacency[current][index];
        } else {
            reverse_path[path_count++] = stack[--top];
        }
    }
    if (path_count != edges + 1) return 0;
    const auto bytes = path_count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t index = 0; index < path_count; ++index) {
        put_i64(output, index * 8, static_cast<std::int64_t>(reverse_path[path_count - index - 1]));
    }
    return static_cast<std::int64_t>(bytes);
}
