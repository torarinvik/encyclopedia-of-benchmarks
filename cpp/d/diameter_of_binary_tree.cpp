// Count the path through the selected node, matching Node.diameter().
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;
constexpr std::int64_t error_sentinel = -2'000'000'000;

std::int64_t height_and_check(const std::int64_t *nodes, std::size_t count,
                              std::int64_t node, bool *seen, std::size_t &visited) {
    if (node == -1) return 0;
    if (node < 0 || static_cast<std::uint64_t>(node) >= count) return error_sentinel;
    const auto index = static_cast<std::size_t>(node);
    if (seen[index]) return error_sentinel;
    seen[index] = true;
    ++visited;
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (left < -1 || right < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= count) ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= count)) return error_sentinel;
    const auto left_height = height_and_check(nodes, count, left, seen, visited);
    if (left_height == error_sentinel) return error_sentinel;
    const auto right_height = height_and_check(nodes, count, right, seen, visited);
    if (right_height == error_sentinel) return error_sentinel;
    return 1 + (left_height > right_height ? left_height : right_height);
}
}

extern "C" std::int64_t diameter_of_binary_tree(const std::int64_t *nodes,
    std::size_t node_count, std::int64_t root_index) noexcept {
    if (nodes == nullptr || node_count == 0 || node_count > max_node_count || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count) return -1;
    bool seen[max_node_count]{};
    std::size_t visited = 1;
    const auto root = static_cast<std::size_t>(root_index);
    seen[root] = true;
    const auto left = nodes[3 * root + 1];
    const auto right = nodes[3 * root + 2];
    if (left < -1 || right < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
    const auto left_height = height_and_check(nodes, node_count, left, seen, visited);
    if (left_height == error_sentinel) return -1;
    const auto right_height = height_and_check(nodes, node_count, right, seen, visited);
    if (right_height == error_sentinel || visited != node_count) return -1;
    return left_height + right_height + 1;
}
