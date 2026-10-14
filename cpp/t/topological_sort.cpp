/* Kahn topological sort over a bounded directed graph encoded as edge pairs. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t topological_sort(const std::int64_t *values, std::size_t length,
                                          std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto edge_count = (length - 1) / 2;
    std::uint64_t adjacency[64]{};
    std::size_t indegree[64]{};
    std::size_t queue[64], order[64];

    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin_value = values[1 + 2 * edge];
        const auto destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(origin_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices) return -2;
        const auto origin = static_cast<std::size_t>(origin_value);
        const auto destination = static_cast<std::size_t>(destination_value);
        const auto mask = UINT64_C(1) << destination;
        if ((adjacency[origin] & mask) == 0) {
            adjacency[origin] |= mask;
            ++indegree[destination];
        }
    }
    std::size_t head = 0, tail = 0;
    for (std::size_t vertex = 0; vertex < vertices; ++vertex)
        if (indegree[vertex] == 0) queue[tail++] = vertex;
    std::size_t count = 0;
    while (head < tail) {
        const auto origin = queue[head++];
        order[count++] = origin;
        for (std::size_t destination = 0; destination < vertices; ++destination) {
            if ((adjacency[origin] & (UINT64_C(1) << destination)) != 0) {
                if (--indegree[destination] == 0) queue[tail++] = destination;
            }
        }
    }
    if (count != vertices) return -1;
    if (output_capacity < vertices || (vertices != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index)
        output[index] = static_cast<std::uint8_t>(order[index]);
    return static_cast<std::int64_t>(count);
}
