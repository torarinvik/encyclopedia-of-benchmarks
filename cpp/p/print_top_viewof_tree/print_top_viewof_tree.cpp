/* BFS top view: first node encountered at each horizontal distance. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 1023;
}

extern "C" std::int64_t print_top_viewof_tree(const std::int64_t *nodes,
    std::size_t node_count, std::int64_t root_index, std::int64_t *output_values,
    std::size_t output_capacity, std::size_t *column_offsets,
    std::size_t offsets_capacity, std::size_t *queue, std::size_t queue_capacity)
{
    if (node_count > max_nodes) return -1;
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (column_offsets == nullptr || offsets_capacity < 1) return -2;
        column_offsets[0] = 0; return 0;
    }
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count) return -1;
    if (output_values == nullptr || output_capacity < node_count || column_offsets == nullptr ||
        offsets_capacity < node_count + 1 || queue == nullptr || queue_capacity < node_count) return -2;
    std::size_t parents[max_nodes]{};
    for (std::size_t node = 0; node < node_count; ++node) {
        const auto value = nodes[3 * node], left = nodes[3 * node + 1], right = nodes[3 * node + 2];
        if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
            (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
            (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
        if (left >= 0 && ++parents[static_cast<std::size_t>(left)] > 1) return -1;
        if (right >= 0 && ++parents[static_cast<std::size_t>(right)] > 1) return -1;
    }
    if (parents[static_cast<std::size_t>(root_index)] != 0) return -1;
    for (std::size_t node = 0; node < node_count; ++node)
        if (node != static_cast<std::size_t>(root_index) && parents[node] != 1) return -1;
    std::int64_t column[max_nodes];
    bool visited[max_nodes]{}, seen_column[2 * max_nodes + 1]{};
    std::size_t head = 0, tail = 1, reached = 0;
    std::size_t written = 0;
    column_offsets[0] = 0;
    queue[0] = static_cast<std::size_t>(root_index); column[static_cast<std::size_t>(root_index)] = 0;
    visited[static_cast<std::size_t>(root_index)] = true;
    while (head < tail) {
        const auto node = queue[head++];
        const auto coordinate = column[node];
        const auto slot = static_cast<std::size_t>(coordinate + static_cast<std::int64_t>(max_nodes));
        if (!seen_column[slot]) {
            seen_column[slot] = true;
            output_values[written] = nodes[3 * node];
            ++written;
            column_offsets[written] = written;
        }
        ++reached;
        const auto left = nodes[3 * node + 1], right = nodes[3 * node + 2];
        if (left >= 0) {
            const auto child = static_cast<std::size_t>(left);
            if (visited[child] || tail >= queue_capacity) return -1;
            visited[child] = true; column[child] = coordinate - 1; queue[tail++] = child;
        }
        if (right >= 0) {
            const auto child = static_cast<std::size_t>(right);
            if (visited[child] || tail >= queue_capacity) return -1;
            visited[child] = true; column[child] = coordinate + 1; queue[tail++] = child;
        }
    }
    if (reached != node_count) return -1;
    return static_cast<std::int64_t>(written);
}
