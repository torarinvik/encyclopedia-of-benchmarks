/* Eagerly materialize a BST's in-order sequence, then consume it through an iterator. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_node_count = 1023; constexpr std::int64_t value_offset = 100001; }

extern "C" std::int64_t bst_iterator(const std::int64_t *nodes, std::size_t node_count,
                                      std::int64_t root_index) noexcept {
    if (node_count > max_node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count) return -1;
    std::int64_t iterator_values[max_node_count];
    std::size_t stack[max_node_count];
    std::size_t top = 0, value_count = 0;
    auto current = root_index;
    while (current != -1 || top != 0) {
        while (current != -1) {
            if (current < 0 || static_cast<std::uint64_t>(current) >= node_count || top >= node_count) return -1;
            const auto index = static_cast<std::size_t>(current);
            const auto left = nodes[3 * index + 1], right = nodes[3 * index + 2];
            if (left < -1 || (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
                right < -1 || (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
            stack[top++] = index;
            current = left;
        }
        const auto index = stack[--top];
        if (value_count >= node_count) return -1;
        const auto value = nodes[3 * index];
        if (value < -100000 || value > 100000 ||
            (value_count != 0 && iterator_values[value_count - 1] >= value)) return -1;
        iterator_values[value_count++] = value;
        current = nodes[3 * index + 2];
    }
    if (value_count != node_count) return -1;
    std::int64_t checksum = 0;
    for (std::size_t next_index = 0; next_index < value_count; ++next_index)
        checksum += (static_cast<std::int64_t>(next_index) + 1) * (iterator_values[next_index] + value_offset);
    return checksum;
}
