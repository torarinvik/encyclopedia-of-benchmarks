/* Recursive reachability search in a bounded undirected graph. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_edges = 256;
constexpr std::size_t max_input_length = 518;
constexpr std::size_t adjacency_capacity = max_vertices * max_vertices;

bool reachable(const std::array<std::size_t, adjacency_capacity> &adjacency,
               const std::array<std::size_t, max_vertices> &degree,
               std::size_t current, std::int64_t target,
               std::array<bool, max_vertices> &visited) noexcept
{
    if (static_cast<std::int64_t>(current) == target) return true;
    visited[current] = true;
    for (std::size_t position = 0; position < degree[current]; ++position) {
        const auto neighbor = adjacency[current * max_vertices + position];
        if (!visited[neighbor] && reachable(adjacency, degree, neighbor, target, visited)) return true;
    }
    return false;
}
}

extern "C" std::int64_t depth_first_search_recursive(const std::int64_t *input,
                                                       std::size_t length) noexcept
{
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const auto vertex_count = input[0];
    const auto edge_count_value = input[1];
    const auto source = input[2];
    const auto target = input[3];
    if (vertex_count < 1 || vertex_count > static_cast<std::int64_t>(max_vertices)
        || edge_count_value < 0 || edge_count_value > static_cast<std::int64_t>(max_edges)
        || source < 0 || source >= vertex_count) return -1;
    const auto edge_count = static_cast<std::size_t>(edge_count_value);
    if (length != 4 + 2 * edge_count) return -1;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = input[4 + 2 * edge];
        const auto right = input[5 + 2 * edge];
        if (left < 0 || left >= vertex_count || right < 0 || right >= vertex_count) return -1;
    }

    std::array<std::size_t, adjacency_capacity> adjacency;
    std::array<std::size_t, max_vertices> degree{};
    std::array<std::uint64_t, max_vertices> seen{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = static_cast<std::size_t>(input[4 + 2 * edge]);
        const auto right = static_cast<std::size_t>(input[5 + 2 * edge]);
        const auto right_bit = UINT64_C(1) << right;
        if ((seen[left] & right_bit) == 0) {
            seen[left] |= right_bit;
            adjacency[left * max_vertices + degree[left]++] = right;
        }
        const auto left_bit = UINT64_C(1) << left;
        if ((seen[right] & left_bit) == 0) {
            seen[right] |= left_bit;
            adjacency[right * max_vertices + degree[right]++] = left;
        }
    }
    std::array<bool, max_vertices> visited{};
    return reachable(adjacency, degree, static_cast<std::size_t>(source), target, visited) ? 1 : 0;
}
