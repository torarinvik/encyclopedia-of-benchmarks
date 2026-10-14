/* Breadth-first binary-tree traversal with caller-owned output and queue arrays. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t level_order_traversal(
    const std::int64_t *nodes, std::size_t node_count, std::int64_t root_index,
    std::int64_t *output_values, std::size_t output_capacity,
    std::size_t *level_offsets, std::size_t level_offsets_capacity,
    std::size_t *queue, std::size_t queue_capacity) noexcept
{
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (level_offsets == nullptr || level_offsets_capacity < 1) return -2;
        level_offsets[0] = 0;
        return 0;
    }
    if (node_count > 4096 || nodes == nullptr || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count)
        return -1;
    if (output_values == nullptr || output_capacity < node_count || level_offsets == nullptr ||
        level_offsets_capacity < node_count + 1 || queue == nullptr || queue_capacity < node_count)
        return -2;

    std::size_t head = 0, tail = 1, visited = 0, levels = 0;
    queue[0] = static_cast<std::size_t>(root_index);
    level_offsets[0] = 0;
    while (head < tail) {
        const std::size_t level_end = tail;
        while (head < level_end) {
            const std::size_t node = queue[head++];
            output_values[visited++] = nodes[3 * node];
            const std::int64_t left = nodes[3 * node + 1];
            const std::int64_t right = nodes[3 * node + 2];
            if (left < -1 || right < -1 ||
                (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
                (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
            if (left >= 0) {
                if (tail >= queue_capacity || tail >= node_count) return -1;
                queue[tail++] = static_cast<std::size_t>(left);
            }
            if (right >= 0) {
                if (tail >= queue_capacity || tail >= node_count) return -1;
                queue[tail++] = static_cast<std::size_t>(right);
            }
        }
        level_offsets[++levels] = visited;
    }
    if (visited != node_count) return -1;
    return static_cast<std::int64_t>(levels);
}
