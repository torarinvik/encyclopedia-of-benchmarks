/* Normalize the simple undirected C graph ADT to a row-major adjacency matrix. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32;
constexpr std::size_t max_edges = 2047;
void put_i64(std::uint8_t *output, std::size_t slot, std::int64_t value) noexcept
{
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[slot * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t graph_c_undirected_simple(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_edges)) return -1;
    const auto vertices = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edge_count) return -1;

    std::uint8_t adjacency[max_vertices][max_vertices]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left_value = input[2 + 2 * edge], right_value = input[3 + 2 * edge];
        if (left_value < 0 || right_value < 0 || static_cast<std::uint64_t>(left_value) >= vertices ||
            static_cast<std::uint64_t>(right_value) >= vertices) return -1;
        const auto left = static_cast<std::size_t>(left_value), right = static_cast<std::size_t>(right_value);
        adjacency[left][right] = 1;
        adjacency[right][left] = 1;
    }
    const auto count = vertices * vertices;
    if (output == nullptr || capacity < count * 8) return -2;
    for (std::size_t row = 0; row < vertices; ++row)
        for (std::size_t column = 0; column < vertices; ++column)
            put_i64(output, row * vertices + column, adjacency[row][column]);
    return static_cast<std::int64_t>(count * 8);
}
