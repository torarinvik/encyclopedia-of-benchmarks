/* Recursive mirror comparison for an indexed binary tree. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;

std::int64_t mirror(const std::int64_t *nodes, std::size_t node_count,
                    std::int64_t left, std::int64_t right) noexcept
{
    if (left == -1 || right == -1) return left == right ? 1 : 0;
    if (left < 0 || right < 0 || static_cast<std::uint64_t>(left) >= node_count ||
        static_cast<std::uint64_t>(right) >= node_count) return -1;
    const auto left_node = static_cast<std::size_t>(left);
    const auto right_node = static_cast<std::size_t>(right);
    if (nodes[3 * left_node] != nodes[3 * right_node]) return 0;
    const auto left_left = nodes[3 * left_node + 1];
    const auto left_right = nodes[3 * left_node + 2];
    const auto right_left = nodes[3 * right_node + 1];
    const auto right_right = nodes[3 * right_node + 2];
    if (left_left < -1 || left_left >= static_cast<std::int64_t>(node_count) ||
        left_right < -1 || left_right >= static_cast<std::int64_t>(node_count) ||
        right_left < -1 || right_left >= static_cast<std::int64_t>(node_count) ||
        right_right < -1 || right_right >= static_cast<std::int64_t>(node_count)) return -1;
    const auto outer = mirror(nodes, node_count, left_left, right_right);
    if (outer != 1) return outer;
    return mirror(nodes, node_count, left_right, right_left);
}
}

extern "C" std::int64_t symmetric_tree(const std::int64_t *nodes,
                                         std::size_t node_count,
                                         std::int64_t root_index) noexcept
{
    if (node_count > max_node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == nullptr || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count) return -1;
    const auto root = static_cast<std::size_t>(root_index);
    const auto left = nodes[3 * root + 1];
    const auto right = nodes[3 * root + 2];
    if (left < -1 || left >= static_cast<std::int64_t>(node_count) ||
        right < -1 || right >= static_cast<std::int64_t>(node_count)) return -1;
    return mirror(nodes, node_count, left, right);
}
