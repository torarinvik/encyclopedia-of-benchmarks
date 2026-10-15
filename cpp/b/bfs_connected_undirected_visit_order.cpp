/* Traverse a connected undirected graph from vertex zero in sorted-neighbor BFS order. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 40;
constexpr std::size_t max_edges = 780;
void put_i64(std::uint8_t *output, std::size_t slot, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[slot * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t bfs_connected_undirected_visit_order(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_edges) || input[2] != 0) return -1;
    const auto vertices = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 3 + 2 * edge_count) return -1;

    std::uint64_t adjacency[max_vertices]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left_value = input[3 + 2 * edge], right_value = input[4 + 2 * edge];
        if (left_value < 0 || right_value < 0 || static_cast<std::uint64_t>(left_value) >= vertices ||
            static_cast<std::uint64_t>(right_value) >= vertices) return -1;
        const auto left = static_cast<std::size_t>(left_value), right = static_cast<std::size_t>(right_value);
        adjacency[left] |= UINT64_C(1) << right;
        adjacency[right] |= UINT64_C(1) << left;
    }
    bool visited[max_vertices]{};
    std::size_t queue[max_vertices]{}, order[max_vertices]{};
    std::size_t head = 0, tail = 0, count = 0;
    visited[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        const auto vertex = queue[head++];
        order[count++] = vertex;
        for (std::size_t neighbor = 0; neighbor < vertices; ++neighbor) {
            if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) != 0 && !visited[neighbor]) {
                visited[neighbor] = true;
                queue[tail++] = neighbor;
            }
        }
    }
    if (count != vertices) return -1;
    if (output == nullptr || capacity < vertices * 8) return -2;
    for (std::size_t index = 0; index < count; ++index) put_i64(output, index, static_cast<std::int64_t>(order[index]));
    return static_cast<std::int64_t>(count);
}
