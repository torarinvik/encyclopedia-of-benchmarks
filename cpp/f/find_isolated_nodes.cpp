#include <cstddef>
#include <cstdint>

// Return vertices with no outgoing neighbors, in ascending vertex order.
extern "C" std::int64_t find_isolated_nodes(const std::int64_t *values, std::size_t length,
                                            std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > 65 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    const auto vertices = static_cast<std::size_t>(values[0]);
    std::uint64_t adjacency[64]{};
    const auto edge_count = (length - 1) / 2;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin_value = values[1 + 2 * edge];
        const auto destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            static_cast<std::uint64_t>(origin_value) >= vertices ||
            static_cast<std::uint64_t>(destination_value) >= vertices) return -2;
        adjacency[static_cast<std::size_t>(origin_value)] |= UINT64_C(1) << static_cast<std::size_t>(destination_value);
    }
    std::uint8_t isolated[64]{};
    std::size_t count = 0;
    for (std::size_t vertex = 0; vertex < vertices; ++vertex)
        if (adjacency[vertex] == 0) isolated[count++] = static_cast<std::uint8_t>(vertex);
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index) output[index] = isolated[index];
    return static_cast<std::int64_t>(count);
}
