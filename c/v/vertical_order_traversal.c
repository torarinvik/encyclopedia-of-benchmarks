/* Breadth-first visitation with stable per-column buckets. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 1023
#define COLUMN_COUNT (2 * MAX_NODES + 1)

int64_t vertical_order_traversal(const int64_t *nodes, size_t node_count, int64_t root_index,
    int64_t *output_values, size_t output_capacity, size_t *column_offsets,
    size_t offsets_capacity, size_t *queue, size_t queue_capacity)
{
    if (node_count > MAX_NODES) return -1;
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (column_offsets == NULL || offsets_capacity < 1) return -2;
        column_offsets[0] = 0;
        return 0;
    }
    if (nodes == NULL || root_index < 0 || (uint64_t)root_index >= node_count) return -1;
    if (output_values == NULL || output_capacity < node_count || column_offsets == NULL ||
        offsets_capacity < node_count + 1 || queue == NULL || queue_capacity < node_count) return -2;
    size_t parents[MAX_NODES] = {0};
    for (size_t node = 0; node < node_count; ++node) {
        const int64_t value = nodes[3 * node];
        const int64_t left = nodes[3 * node + 1], right = nodes[3 * node + 2];
        if (value < INT32_MIN || value > INT32_MAX || left < -1 || right < -1 ||
            (left >= 0 && (uint64_t)left >= node_count) || (right >= 0 && (uint64_t)right >= node_count)) return -1;
        if (left >= 0 && ++parents[(size_t)left] > 1) return -1;
        if (right >= 0 && ++parents[(size_t)right] > 1) return -1;
    }
    if (parents[(size_t)root_index] != 0) return -1;
    for (size_t node = 0; node < node_count; ++node)
        if (node != (size_t)root_index && parents[node] != 1) return -1;

    int64_t column[MAX_NODES], next_in_column[MAX_NODES];
    int64_t bucket_head[COLUMN_COUNT], bucket_tail[COLUMN_COUNT];
    uint8_t visited[MAX_NODES] = {0};
    for (size_t i = 0; i < COLUMN_COUNT; ++i) bucket_head[i] = bucket_tail[i] = -1;
    size_t head = 0, tail = 1, reached = 0;
    int64_t minimum = 0, maximum = 0;
    queue[0] = (size_t)root_index;
    column[(size_t)root_index] = 0;
    visited[(size_t)root_index] = 1;
    while (head < tail) {
        const size_t node = queue[head++];
        const int64_t current_column = column[node];
        const size_t slot = (size_t)(current_column + MAX_NODES);
        next_in_column[node] = -1;
        if (bucket_head[slot] < 0) bucket_head[slot] = (int64_t)node;
        else next_in_column[(size_t)bucket_tail[slot]] = (int64_t)node;
        bucket_tail[slot] = (int64_t)node;
        ++reached;
        const int64_t left = nodes[3 * node + 1], right = nodes[3 * node + 2];
        if (left >= 0) {
            const size_t child = (size_t)left;
            if (visited[child] || tail >= queue_capacity) return -1;
            visited[child] = 1; column[child] = current_column - 1; queue[tail++] = child;
            if (column[child] < minimum) minimum = column[child];
        }
        if (right >= 0) {
            const size_t child = (size_t)right;
            if (visited[child] || tail >= queue_capacity) return -1;
            visited[child] = 1; column[child] = current_column + 1; queue[tail++] = child;
            if (column[child] > maximum) maximum = column[child];
        }
    }
    if (reached != node_count) return -1;
    size_t written = 0, column_count = 0;
    column_offsets[0] = 0;
    for (int64_t coordinate = minimum; coordinate <= maximum; ++coordinate) {
        const size_t slot = (size_t)(coordinate + MAX_NODES);
        for (int64_t node = bucket_head[slot]; node >= 0; node = next_in_column[(size_t)node])
            output_values[written++] = nodes[3 * (size_t)node];
        column_offsets[++column_count] = written;
    }
    return (int64_t)column_count;
}
