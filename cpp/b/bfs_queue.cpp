#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVertexCount = 64;
constexpr std::size_t MaxEdgeCount = 2046;
constexpr std::size_t MaxInputLength = 4 + 2 * MaxEdgeCount;
}

extern "C" std::int64_t bfs_queue(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 4 || length > MaxInputLength || input[0] < 1 ||
        input[0] > static_cast<std::int64_t>(MaxVertexCount) || input[3] < 0 ||
        input[3] > static_cast<std::int64_t>(MaxEdgeCount)) return -1;
    const auto vertex_count = static_cast<std::size_t>(input[0]);
    const auto source_arg = input[1], target_arg = input[2];
    const auto edge_count = static_cast<std::size_t>(input[3]);
    if (source_arg < 0 || source_arg >= static_cast<std::int64_t>(vertex_count) ||
        target_arg < 0 || target_arg >= static_cast<std::int64_t>(vertex_count) ||
        length != 4 + 2 * edge_count) return -1;

    std::uint64_t adjacency[MaxVertexCount]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left_arg = input[4 + 2 * edge], right_arg = input[5 + 2 * edge];
        if (left_arg < 0 || right_arg < 0 || left_arg >= static_cast<std::int64_t>(vertex_count) ||
            right_arg >= static_cast<std::int64_t>(vertex_count)) return -1;
        const auto left = static_cast<std::size_t>(left_arg), right = static_cast<std::size_t>(right_arg);
        adjacency[left] |= UINT64_C(1) << right;
        adjacency[right] |= UINT64_C(1) << left;
    }

    const auto source = static_cast<std::size_t>(source_arg), target = static_cast<std::size_t>(target_arg);
    std::int64_t predecessor[MaxVertexCount];
    bool visited[MaxVertexCount]{};
    std::size_t queue[MaxVertexCount]{}, head = 0, tail = 0;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) predecessor[vertex] = -1;
    predecessor[source] = static_cast<std::int64_t>(source);
    visited[source] = true;
    queue[tail++] = source;
    bool found = source == target;
    while (head < tail && !found) {
        const auto current = queue[head++];
        for (std::size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
            if ((adjacency[current] & (UINT64_C(1) << neighbor)) == 0 || visited[neighbor]) continue;
            visited[neighbor] = true;
            predecessor[neighbor] = static_cast<std::int64_t>(current);
            if (neighbor == target) { found = true; break; }
            queue[tail++] = neighbor;
        }
    }
    if (!found) {
        if (output_capacity < 1 || output == nullptr) return -2;
        output[0] = 0;
        return 1;
    }

    std::uint8_t path[MaxVertexCount];
    std::size_t path_length = 0, current = target;
    while (current != source) {
        path[path_length++] = static_cast<std::uint8_t>(current);
        current = static_cast<std::size_t>(predecessor[current]);
    }
    path[path_length++] = static_cast<std::uint8_t>(source);
    if (output_capacity < path_length + 1 || output == nullptr) return -2;
    output[0] = 1;
    for (std::size_t index = 0; index < path_length; ++index) output[index + 1] = path[index];
    return static_cast<std::int64_t>(path_length + 1);
}
