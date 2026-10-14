/* Breadth-first binary-tree traversal with caller-owned output and queue arrays. */
#include <stddef.h>
#include <stdint.h>
#include <limits.h>

int64_t level_order_traversal(const int64_t *nodes, size_t node_count, int64_t root_index,
                              int64_t *output_values, size_t output_capacity,
                              size_t *level_offsets, size_t level_offsets_capacity,
                              size_t *queue, size_t queue_capacity)
{
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (level_offsets == NULL || level_offsets_capacity < 1) return -2;
        level_offsets[0] = 0;
        return 0;
    }
    if (node_count > 4096 || nodes == NULL || root_index < 0 || (uint64_t)root_index >= (uint64_t)node_count ||
        node_count > (size_t)INT64_MAX) return -1;
    if (output_values == NULL || output_capacity < node_count ||
        level_offsets == NULL || level_offsets_capacity < node_count + 1 ||
        queue == NULL || queue_capacity < node_count) return -2;

    size_t head = 0;
    size_t tail = 1;
    size_t visited = 0;
    size_t levels = 0;
    queue[0] = (size_t)root_index;
    level_offsets[0] = 0;
    while (head < tail) {
        const size_t level_end = tail;
        while (head < level_end) {
            const size_t node = queue[head++];
            output_values[visited++] = nodes[3 * node];
            const int64_t left = nodes[3 * node + 1];
            const int64_t right = nodes[3 * node + 2];
            if (left < -1 || right < -1 ||
                (left >= 0 && (uint64_t)left >= (uint64_t)node_count) ||
                (right >= 0 && (uint64_t)right >= (uint64_t)node_count)) return -1;
            if (left >= 0) {
                if (tail >= queue_capacity || tail >= node_count) return -1;
                queue[tail++] = (size_t)left;
            }
            if (right >= 0) {
                if (tail >= queue_capacity || tail >= node_count) return -1;
                queue[tail++] = (size_t)right;
            }
        }
        level_offsets[++levels] = visited;
    }
    if (visited != node_count) return -1;
    return (int64_t)levels;
}
