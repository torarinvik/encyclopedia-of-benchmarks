#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cycle_check_directed_graph_kahn(const std::int64_t *values,
                                                        std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > 65 || (length - 1) % 2 != 0) return -1;
    if (values[0] < 0 || values[0] > 64) return -1;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto edge_count = (length - 1) / 2;
    if (edge_count > 32) return -1;
    std::uint64_t adjacency[64]{};
    std::size_t indegree[64]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto source_value = values[1 + 2 * edge];
        const auto destination_value = values[2 + 2 * edge];
        if (source_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(source_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices) return -1;
        const auto source = static_cast<std::size_t>(source_value);
        const auto destination = static_cast<std::size_t>(destination_value);
        const auto mask = UINT64_C(1) << destination;
        if ((adjacency[source] & mask) == 0) {
            adjacency[source] |= mask;
            ++indegree[destination];
        }
    }
    std::size_t queue[64], head = 0, tail = 0;
    for (std::size_t vertex = 0; vertex < vertices; ++vertex)
        if (indegree[vertex] == 0) queue[tail++] = vertex;
    std::size_t removed = 0;
    while (head < tail) {
        const auto source = queue[head++];
        ++removed;
        for (std::size_t destination = 0; destination < vertices; ++destination) {
            if ((adjacency[source] & (UINT64_C(1) << destination)) == 0) continue;
            if (--indegree[destination] == 0) queue[tail++] = destination;
        }
    }
    return removed == vertices ? 0 : 1;
}
