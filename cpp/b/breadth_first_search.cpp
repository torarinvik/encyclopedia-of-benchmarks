#include <cstddef>
#include <cstdint>

// Traverse the directed graph from start using an explicit fixed-capacity graph.
extern "C" std::int64_t breadth_first_search(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > 66 || (length - 2) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto start_value = values[1];
    if (vertices == 0) return start_value == -1 && length == 2 ? 0 : -2;
    if (start_value < 0 || static_cast<std::uint64_t>(start_value) >= vertices) return -2;
    std::uint64_t adjacency[64]{};
    bool visited[64]{};
    const auto edge_count = (length - 2) / 2;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin_value = values[2 + 2 * edge];
        const auto destination_value = values[3 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(origin_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices) return -2;
        adjacency[static_cast<std::size_t>(origin_value)] |= UINT64_C(1) << static_cast<std::size_t>(destination_value);
    }
    const auto start = static_cast<std::size_t>(start_value);
    std::size_t order[64]{};
    std::size_t count = 0;
    visited[start] = true;
    std::size_t queue[64]{};
    std::size_t head = 0, tail = 0;
    queue[tail++] = start;
    while (head < tail) {
        const auto origin = queue[head++];
        order[count++] = origin;
        for (std::size_t destination = 0; destination < vertices; ++destination) {
            if ((adjacency[origin] & (UINT64_C(1) << destination)) != 0 && !visited[destination]) {
                visited[destination] = true;
                queue[tail++] = destination;
            }
        }
    }
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index)
        output[index] = static_cast<std::uint8_t>(order[index]);
    return static_cast<std::int64_t>(count);
}
