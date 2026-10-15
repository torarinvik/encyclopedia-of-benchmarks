// Return the edge that first closes the cycle under input-order union-find.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 1000;

std::int32_t find_root(std::int32_t *parents, std::int32_t node) noexcept {
    std::int32_t root = node;
    while (parents[root] != root) root = parents[root];
    while (parents[node] != node) {
        const auto next = parents[node];
        parents[node] = root;
        node = next;
    }
    return root;
}
}

extern "C" std::int64_t redundant_connection(
        const std::int64_t *values, std::size_t length,
        std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length < 6 || length > 2 * max_vertices || (length & 1U) != 0 || values == nullptr) return -1;
    const std::size_t edge_count = length / 2;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 1 || values[index] > static_cast<std::int64_t>(edge_count)) return -1;
    for (std::size_t edge = 0; edge < edge_count; ++edge)
        if (values[2 * edge] == values[2 * edge + 1]) return -1;

    std::int32_t parents[max_vertices + 1];
    for (std::size_t node = 0; node <= edge_count; ++node) parents[node] = static_cast<std::int32_t>(node);
    std::int64_t redundant_left = 0, redundant_right = 0;
    std::size_t redundant_count = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = static_cast<std::int32_t>(values[2 * edge]);
        const auto right = static_cast<std::int32_t>(values[2 * edge + 1]);
        const auto left_root = find_root(parents, left);
        const auto right_root = find_root(parents, right);
        if (left_root == right_root) {
            redundant_left = left;
            redundant_right = right;
            ++redundant_count;
        } else {
            parents[left_root] = right_root;
        }
    }
    if (redundant_count != 1) return -1;
    if (output_capacity < 8 || output == nullptr) return -2;
    const std::uint32_t endpoints[2] = {static_cast<std::uint32_t>(redundant_left),
                                        static_cast<std::uint32_t>(redundant_right)};
    for (std::size_t endpoint = 0; endpoint < 2; ++endpoint)
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[endpoint * 4 + byte] = static_cast<std::uint8_t>(endpoints[endpoint] >> (byte * 8));
    return 2;
}
