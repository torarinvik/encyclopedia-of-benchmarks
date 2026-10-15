#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxNodeCount = 256;
constexpr std::size_t MaxEdgeCount = 2047;

std::size_t find_root(std::size_t parent[MaxNodeCount + 1], std::size_t node) noexcept
{
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}
}

extern "C" std::int64_t connected_components_with_dsu(
    const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || input[0] < 0 ||
        input[0] > static_cast<std::int64_t>(MaxNodeCount) || input[1] < 0 ||
        input[1] > static_cast<std::int64_t>(MaxEdgeCount)) return -1;
    const auto node_count = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edge_count) return -1;

    std::size_t parent[MaxNodeCount + 1], set_size[MaxNodeCount + 1];
    for (std::size_t node = 1; node <= node_count; ++node) {
        parent[node] = node;
        set_size[node] = 1;
    }
    auto component_count = node_count;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left_arg = input[2 + 2 * edge], right_arg = input[3 + 2 * edge];
        if (left_arg < 1 || left_arg > static_cast<std::int64_t>(node_count) ||
            right_arg < 1 || right_arg > static_cast<std::int64_t>(node_count)) return -1;
        auto left = find_root(parent, static_cast<std::size_t>(left_arg));
        auto right = find_root(parent, static_cast<std::size_t>(right_arg));
        if (left == right) continue;
        if (set_size[left] < set_size[right]) { const auto temporary = left; left = right; right = temporary; }
        parent[right] = left;
        set_size[left] += set_size[right];
        --component_count;
    }
    return static_cast<std::int64_t>(component_count);
}
