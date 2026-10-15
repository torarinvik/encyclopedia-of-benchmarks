/* Recursively check that every indexed-tree node matches its parent value. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;

std::int64_t is_univalued(const std::int64_t *nodes, std::size_t node_count,
                          std::int64_t node) noexcept
{
    if (node == -1) return 1;
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count) return -1;
    const auto index = static_cast<std::size_t>(node);
    const auto value = nodes[3 * index];
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        right < -1 || (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
    if ((left >= 0 && nodes[3 * static_cast<std::size_t>(left)] != value) ||
        (right >= 0 && nodes[3 * static_cast<std::size_t>(right)] != value)) return 0;
    const auto left_result = is_univalued(nodes, node_count, left);
    if (left_result <= 0) return left_result;
    return is_univalued(nodes, node_count, right);
}
}

extern "C" std::int64_t univalued_binary_tree(const std::int64_t *nodes,
                                              std::size_t node_count,
                                              std::int64_t root_index) noexcept
{
    if (node_count > max_node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count)
        return -1;
    return is_univalued(nodes, node_count, root_index);
}
